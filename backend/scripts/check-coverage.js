# scripts/check-coverage.js
const fs = require('fs');
const path = require('path');

// Coverage thresholds as per requirements
const THRESHOLDS = {
  overall: 80,
  auth: 90,
  payroll: 95,
  taxes: 95,
  mpesa: 85,
  workers: 80,
  subscriptions: 70,
};

function parseCoverageReport(coveragePath) {
  try {
    const content = fs.readFileSync(coveragePath, 'utf8');
    const data = JSON.parse(content);
    
    // Extract coverage data by file/module
    const fileCoverage = {};
    
    if (data.l && Object.keys(data.l).length > 0) {
      // Parse line coverage data
      Object.keys(data.l).forEach(file => {
        const lines = data.l[file];
        const totalLines = Object.keys(lines).length;
        const coveredLines = Object.values(lines).filter(hits => hits > 0).length;
        const percentage = totalLines > 0 ? (coveredLines / totalLines) * 100 : 100;
        
        fileCoverage[path.basename(file)] = {
          totalLines,
          coveredLines,
          percentage: Math.round(percentage * 100) / 100
        };
      });
    }
    
    return fileCoverage;
  } catch (error) {
    console.error('Error parsing coverage report:', error);
    return {};
  }
}

function categorizeFiles(files) {
  const categories = {
    auth: [],
    payroll: [],
    taxes: [],
    mpesa: [],
    workers: [],
    subscriptions: [],
    other: []
  };

  Object.keys(files).forEach(file => {
    const lowerFile = file.toLowerCase();
    
    if (lowerFile.includes('auth') || lowerFile.includes('login')) {
      categories.auth.push(files[file]);
    } else if (lowerFile.includes('payroll') || lowerFile.includes('payslip')) {
      categories.payroll.push(files[file]);
    } else if (lowerFile.includes('tax') || lowerFile.includes('paye')) {
      categories.taxes.push(files[file]);
    } else if (lowerFile.includes('mpesa') || lowerFile.includes('payment')) {
      categories.mpesa.push(files[file]);
    } else if (lowerFile.includes('worker')) {
      categories.workers.push(files[file]);
    } else if (lowerFile.includes('subscription')) {
      categories.subscriptions.push(files[file]);
    } else {
      categories.other.push(files[file]);
    }
  });

  return categories;
}

function calculateCategoryCoverage(files) {
  const categories = categorizeFiles(files);
  const results = {};

  Object.keys(categories).forEach(category => {
    const categoryFiles = categories[category];
    
    if (categoryFiles.length === 0) {
      results[category] = 100; // No files in this category
      return;
    }

    const totalCoverage = categoryFiles.reduce((sum, file) => sum + file.percentage, 0);
    results[category] = Math.round((totalCoverage / categoryFiles.length) * 100) / 100;
  });

  return results;
}

function calculateOverallCoverage(files) {
  const totalCoverage = Object.values(files).reduce((sum, file) => sum + file.percentage, 0);
  return Math.round((totalCoverage / Object.keys(files).length) * 100) / 100;
}

function validateThresholds(coverage) {
  const results = {
    passed: true,
    failures: [],
    warnings: []
  };

  // Check overall coverage
  if (coverage.overall < THRESHOLDS.overall) {
    results.failures.push(`Overall coverage ${coverage.overall}% is below threshold ${THRESHOLDS.overall}%`);
    results.passed = false;
  }

  // Check specific module coverage
  Object.keys(coverage).forEach(module => {
    if (module !== 'overall' && THRESHOLDS[module]) {
      if (coverage[module] < THRESHOLDS[module]) {
        results.failures.push(`${module} coverage ${coverage[module]}% is below threshold ${THRESHOLDS[module]}%`);
        results.passed = false;
      } else if (coverage[module] < THRESHOLDS[module] + 5) {
        results.warnings.push(`${module} coverage ${coverage[module]}% is close to threshold ${THRESHOLDS[module]}%`);
      }
    }
  });

  return results;
}

function generateReport(coverage, fileCoverage, validation) {
  let report = '# Test Coverage Report\n\n';
  
  report += '## Overall Coverage\n';
  report += `**${coverage.overall}%** (Threshold: ${THRESHOLDS.overall}%)\n\n`;
  
  report += '## Module Coverage\n';
  Object.keys(coverage).forEach(module => {
    if (module !== 'overall') {
      const threshold = THRESHOLDS[module] || 70;
      const status = coverage[module] >= threshold ? '✅' : '❌';
      report += `- **${module}**: ${coverage[module]}% ${status} (Threshold: ${threshold}%)\n`;
    }
  });
  
  report += '\n## File Coverage Details\n';
  Object.keys(fileCoverage).sort().forEach(file => {
    const coverage = fileCoverage[file];
    const status = coverage.percentage >= 70 ? '✅' : '⚠️';
    report += `- **${file}**: ${coverage.percentage}% ${status} (${coverage.coveredLines}/${coverage.totalLines} lines)\n`;
  });
  
  if (validation.failures.length > 0) {
    report += '\n## ❌ Coverage Failures\n';
    validation.failures.forEach(failure => {
      report += `- ${failure}\n`;
    });
  }
  
  if (validation.warnings.length > 0) {
    report += '\n## ⚠️ Coverage Warnings\n';
    validation.warnings.forEach(warning => {
      report += `- ${warning}\n`;
    });
  }
  
  report += '\n## Recommendations\n';
  report += '- Focus on increasing coverage for critical modules (Payroll, Taxes)\n';
  report += '- Prioritize testing edge cases and error handling\n';
  report += '- Add integration tests for cross-module functionality\n';
  report += '- Consider implementing property-based testing for tax calculations\n';
  
  return report;
}

function main() {
  console.log('🔍 Checking test coverage...\n');
  
  const coveragePaths = [
    'backend/coverage/coverage-summary.json',
    'backend/coverage/lcov.info',
    'coverage/coverage-summary.json'
  ];
  
  let coverageFile = null;
  for (const path of coveragePaths) {
    if (fs.existsSync(path)) {
      coverageFile = path;
      break;
    }
  }
  
  if (!coverageFile) {
    console.error('❌ No coverage file found. Please run tests with coverage first.');
    process.exit(1);
  }
  
  console.log(`📊 Found coverage file: ${coverageFile}`);
  
  const fileCoverage = parseCoverageReport(coverageFile);
  
  if (Object.keys(fileCoverage).length === 0) {
    console.error('❌ Could not parse coverage data');
    process.exit(1);
  }
  
  const moduleCoverage = calculateCategoryCoverage(fileCoverage);
  const overallCoverage = calculateOverallCoverage(fileCoverage);
  
  const coverage = {
    overall: overallCoverage,
    ...moduleCoverage
  };
  
  const validation = validateThresholds(coverage);
  
  console.log(`📈 Overall Coverage: ${coverage.overall}%`);
  console.log('📋 Module Coverage:');
  Object.keys(moduleCoverage).forEach(module => {
    const threshold = THRESHOLDS[module] || 70;
    const status = moduleCoverage[module] >= threshold ? '✅' : '❌';
    console.log(`  ${module}: ${moduleCoverage[module]}% ${status}`);
  });
  
  if (validation.failures.length > 0) {
    console.log('\n❌ Coverage Failures:');
    validation.failures.forEach(failure => console.log(`  - ${failure}`));
  }
  
  if (validation.warnings.length > 0) {
    console.log('\n⚠️ Coverage Warnings:');
    validation.warnings.forEach(warning => console.log(`  - ${warning}`));
  }
  
  // Generate and save detailed report
  const report = generateReport(coverage, fileCoverage, validation);
  fs.writeFileSync('coverage-report.md', report);
  console.log('\n📄 Detailed report saved to coverage-report.md');
  
  // Exit with appropriate code
  if (validation.passed) {
    console.log('\n✅ All coverage thresholds met!');
    process.exit(0);
  } else {
    console.log('\n❌ Coverage thresholds not met!');
    process.exit(1);
  }
}

main();