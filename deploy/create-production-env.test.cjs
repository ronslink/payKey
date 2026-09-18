const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { createProductionEnvironment } = require("./create-production-env.cjs");

const fixture = {
  DATABASE_URL: "postgresql://local:unused@db.example.invalid:25060/test",
  JWT_SECRET: "unit-test-signing-value-at-least-32-characters",
  REDIS_PASSWORD: "unit-test-redis-password",
  INTASEND_PUBLISHABLE_KEY: "unit-test-public",
  INTASEND_SECRET_KEY: "unit-test-private",
  INTASEND_CHALLENGE: "unit-test-challenge",
  STRIPE_SECRET_KEY: "sk_live_unit_test_only",
  STRIPE_PUBLISHABLE_KEY: "pk_live_unittestonly",
  STRIPE_WEBHOOK_SECRET: "whsec_unit_test_only",
  BACKEND_IMAGE: `example/paykey-backend@sha256:${"a".repeat(64)}`,
  RELEASE_COMMIT: "b".repeat(40),
};

function composeEnvironment(candidate) {
  // Shell variables override --env-file, even when empty. CI deliberately sets
  // DATABASE_URL='' for its isolated database; do not let that or local secrets
  // replace the candidate values whose serialization this test is verifying.
  const environment = { ...process.env };
  for (const [, name] of candidate.matchAll(/^([A-Z][A-Z0-9_]*)=/gm))
    delete environment[name];
  return environment;
}

test("rejects missing live payment verification and mutable image configuration", () => {
  assert.throws(
    () => createProductionEnvironment({ ...fixture, REDIS_PASSWORD: "" }),
    /REDIS_PASSWORD/,
  );
  for (const key of ["", "pk_test_unittestonly", "sk_live_unittestonly"]) {
    assert.throws(
      () =>
        createProductionEnvironment({
          ...fixture,
          STRIPE_PUBLISHABLE_KEY: key,
        }),
      /STRIPE_PUBLISHABLE_KEY/,
    );
  }
  assert.throws(
    () => createProductionEnvironment({ ...fixture, INTASEND_CHALLENGE: "" }),
    /INTASEND_CHALLENGE/,
  );
  assert.throws(
    () =>
      createProductionEnvironment({
        ...fixture,
        BACKEND_IMAGE: "example/paykey-backend:latest",
      }),
    /immutable/,
  );
  assert.throws(
    () =>
      createProductionEnvironment({
        ...fixture,
        STRIPE_SECRET_KEY: "configured-alone",
      }),
    /live Stripe/,
  );
});

test("Compose preserves literal dollars, quotes, backslashes and multiline secrets", () => {
  const directory = fs.mkdtempSync(
    path.join(os.tmpdir(), "paykey-compose-config-"),
  );
  try {
    const values = {
      ...fixture,
      JWT_SECRET: "test$literal${NOT_AN_ENV_VAR}quote'suffix-long-enough",
      REDIS_PASSWORD: String.raw`literal\'quote\\'next$money`,
      APPLE_PRIVATE_KEY:
        "-----BEGIN PRIVATE KEY-----\r\nquote' dollar$ \\backslash\n-----END PRIVATE KEY-----",
    };
    const envPath = path.join(directory, "candidate.env");
    const candidate = createProductionEnvironment(values);
    fs.writeFileSync(envPath, candidate);
    const environment = Object.fromEntries(
      Object.keys(values).map((name) => [name, "${" + name + "}"]),
    );
    const composePath = path.join(directory, "compose.json");
    fs.writeFileSync(
      composePath,
      JSON.stringify({
        services: { fixture: { image: "alpine", environment } },
      }),
    );
    const result = spawnSync(
      "docker",
      [
        "compose",
        "--env-file",
        envPath,
        "-f",
        composePath,
        "config",
        "--format",
        "json",
      ],
      { encoding: "utf8", env: composeEnvironment(candidate) },
    );
    assert.equal(
      result.status,
      0,
      "Docker Compose configuration parsing must succeed (no daemon required)",
    );
    const parsed = JSON.parse(result.stdout).services.fixture.environment;
    // `compose config` escapes dollars for a second Compose parse of its output.
    for (const [name, value] of Object.entries(values))
      assert.equal(
        parsed[name].replace(/\$\$/g, "$"),
        value,
        `${name} must survive Compose parsing`,
      );
  } finally {
    fs.rmSync(directory, { recursive: true });
  }
});

test("production Compose models require immutable image/password and isolate host access", () => {
  const directory = fs.mkdtempSync(
    path.join(os.tmpdir(), "paykey-production-compose-"),
  );
  try {
    const envPath = path.join(directory, "candidate.env");
    const candidate = createProductionEnvironment(fixture);
    fs.writeFileSync(envPath, candidate);
    for (const filename of [
      "docker-compose.backend.yml",
      "docker-compose.infra.yml",
    ]) {
      const result = spawnSync(
        "docker",
        [
          "compose",
          "-p",
          "paykey-config-test",
          "--env-file",
          envPath,
          "-f",
          path.join(__dirname, filename),
          "config",
          "--format",
          "json",
        ],
        { encoding: "utf8", env: composeEnvironment(candidate) },
      );
      assert.equal(result.status, 0, `${filename} must parse`);
      const model = JSON.parse(result.stdout);
      if (model.services.backend) {
        const backend = model.services.backend;
        assert.equal(backend.image, fixture.BACKEND_IMAGE);
        assert.equal(
          backend.environment.STRIPE_PUBLISHABLE_KEY,
          fixture.STRIPE_PUBLISHABLE_KEY,
        );
        assert.equal(backend.environment.STRIPE_WALLET_FUNDING_ENABLED, "false");
        assert.equal(backend.ports[0].host_ip, "127.0.0.1");
        assert.ok(
          !backend.volumes.some(
            (volume) => volume.source === "/var/run/docker.sock",
          ),
        );
        assert.ok(
          backend.volumes.some((volume) => volume.target === "/app/storage"),
        );
        assert.ok(
          backend.volumes.some(
            (volume) =>
              volume.target === "/app/legacy-uploads" && volume.read_only,
          ),
        );
        assert.ok(backend.healthcheck.test.at(-1).endsWith("/health/ready"));
      } else {
        assert.equal(
          model.services.redis.environment.REDIS_PASSWORD,
          fixture.REDIS_PASSWORD,
        );
      }
    }
  } finally {
    fs.rmSync(directory, { recursive: true });
  }
});
