'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');
const { ESLint } = require('eslint');

const root = path.resolve(__dirname, '..');
const baselinePath = path.join(root, 'eslint-baseline.json');

function fingerprint(file, message, source) {
  const lines = source.split(/\r?\n/);
  const firstLine = Math.max(0, (message.line || 1) - 1);
  const lastLine = Math.max(firstLine, (message.endLine || message.line || 1) - 1);
  const span = lines.slice(firstLine, lastLine + 1);
  if (message.endColumn && span.length) span[span.length - 1] = span[span.length - 1].slice(0, message.endColumn - 1);
  if (message.column && span.length) span[0] = span[0].slice(message.column - 1);
  let snippet = span.join(' ').trim().replace(/\s+/g, ' ');
  if (!snippet) {
    // Prettier insertions have a zero-width span. Anchor them to surrounding
    // source instead of its platform-specific CRLF/LF diagnostic message.
    const before = [...lines.slice(0, firstLine), lines[firstLine].slice(0, (message.column || 1) - 1)]
      .join(' ').replace(/\s+/g, ' ').trimEnd().slice(-80);
    const after = [lines[firstLine].slice((message.column || 1) - 1), ...lines.slice(firstLine + 1)]
      .join(' ').replace(/\s+/g, ' ').trimStart().slice(0, 80);
    snippet = `${before}|${after}`;
  }
  const hash = crypto
    .createHash('sha256')
    .update(snippet)
    .digest('hex');
  return `${file}|${message.ruleId || 'parse-error'}|${message.severity}|${hash}`;
}

async function main() {
  process.chdir(root);
  const eslint = new ESLint({ cwd: root, fix: false });
  const generating = process.argv.includes('--generate-from-head');
  const counts = {};
  let results;
  let revision;
  if (generating) {
    revision = execFileSync('git', ['rev-parse', 'HEAD'], {
      cwd: root,
      encoding: 'utf8',
    }).trim();
    const tracked = execFileSync(
      'git',
      ['ls-tree', '-r', '--name-only', revision, '--', 'src', 'test'],
      { cwd: root, encoding: 'utf8' },
    )
      .trim()
      .split('\n')
      .filter((name) => name.endsWith('.ts'));
    results = [];
    for (const file of tracked) {
      const source = execFileSync(
        'git',
        ['show', `${revision}:backend/${file}`],
        { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] },
      );
      const [result] = await eslint.lintText(source, {
        filePath: path.join(root, file),
      });
      if (result) results.push({ ...result, source });
    }
  } else {
    results = await eslint.lintFiles(['src/**/*.ts', 'test/**/*.ts']);
  }

  for (const result of results) {
    const file = path.relative(root, result.filePath).split(path.sep).join('/');
    const source = result.source ?? fs.readFileSync(result.filePath, 'utf8');
    for (const message of result.messages) {
      const key = fingerprint(file, message, source);
      counts[key] = (counts[key] || 0) + 1;
    }
  }

  const totals = {
    errors: results.reduce((sum, result) => sum + result.errorCount, 0),
    warnings: results.reduce((sum, result) => sum + result.warningCount, 0),
  };
  if (generating) {
    fs.writeFileSync(
      baselinePath,
      JSON.stringify(
        {
          revision,
          policy:
            'Legacy diagnostics only; fingerprint is file, rule, severity and normalized source snippet hash. New files have zero allowance.',
          totals,
          counts,
        },
        null,
        2,
      ) + '\n',
    );
    console.log(
      `Recorded committed-source baseline ${revision}: ${totals.errors} errors, ${totals.warnings} warnings. No source snippets or credentials are stored.`,
    );
    return;
  }

  const baseline = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
  const added = Object.entries(counts).filter(
    ([key, count]) => count > (baseline.counts[key] || 0),
  );
  fs.mkdirSync(path.join(root, 'test-results'), { recursive: true });
  const remaining = { ...baseline.counts };
  const regressions = [];
  for (const result of results) {
    const file = path.relative(root, result.filePath).split(path.sep).join('/');
    const source = result.source ?? fs.readFileSync(result.filePath, 'utf8');
    for (const message of result.messages) {
      const key = fingerprint(file, message, source);
      if (remaining[key] > 0) remaining[key] -= 1;
      else regressions.push({ file, ...message });
    }
  }
  fs.writeFileSync(
    path.join(root, 'test-results/lint-regressions.json'),
    JSON.stringify(regressions, null, 2),
  );
  // Retain the complete report as a CI artifact, without source-file contents.
  fs.writeFileSync(
    path.join(root, 'test-results/lint-report.json'),
    JSON.stringify(
      results.map(({ source, ...result }) => result),
      null,
      2,
    ),
  );
  console.log(
    `ESLint: ${totals.errors} errors, ${totals.warnings} warnings; ${added.length} introduced diagnostic fingerprints compared with ${baseline.revision}.`,
  );
  for (const [key, count] of added.slice(0, 30)) {
    const [file, rule, severity] = key.split('|');
    console.error(
      `${file}: ${rule} (severity ${severity}), ${count - (baseline.counts[key] || 0)} introduced`,
    );
  }
  if (added.length) process.exitCode = 1;
}

main().catch(() => {
  console.error(
    'Lint regression check failed to run; check its configuration and committed baseline.',
  );
  process.exitCode = 1;
});
