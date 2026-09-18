"use strict";

const fs = require("node:fs");

const required = [
  "DATABASE_URL",
  "JWT_SECRET",
  "REDIS_PASSWORD",
  "INTASEND_PUBLISHABLE_KEY",
  "INTASEND_SECRET_KEY",
  "STRIPE_SECRET_KEY",
  "STRIPE_WEBHOOK_SECRET",
  "BACKEND_IMAGE",
  "RELEASE_COMMIT",
];
const optional = [
  "INTASEND_CHALLENGE",
  "INTASEND_WEBHOOK_SECRET",
  "GOOGLE_CLIENT_ID",
  "GOOGLE_WEB_CLIENT_ID",
  "APPLE_KEY_ID",
  "APPLE_TEAM_ID",
  "APPLE_BUNDLE_ID",
  "APPLE_PRIVATE_KEY",
  "EMAIL_PROVIDER",
  "SENDGRID_API_KEY",
  "SENDGRID_FROM_EMAIL",
  "SMS_PROVIDER",
  "AFRICANSTALKING_API_KEY",
  "AFRICANSTALKING_USERNAME",
];

function createProductionEnvironment(source) {
  const missing = required.filter((name) => !source[name]?.trim());
  if (missing.length)
    throw new Error(`Missing required configuration: ${missing.join(", ")}`);
  if (
    !source.INTASEND_CHALLENGE?.trim() &&
    !source.INTASEND_WEBHOOK_SECRET?.trim()
  ) {
    throw new Error(
      "An INTASEND_CHALLENGE or INTASEND_WEBHOOK_SECRET is required",
    );
  }
  if (source.JWT_SECRET.length < 32)
    throw new Error("JWT_SECRET must contain at least 32 characters");
  if (source.REDIS_PASSWORD.length < 16)
    throw new Error("REDIS_PASSWORD must contain at least 16 characters");
  if (
    !/^[a-z0-9][a-z0-9._/-]*@sha256:[a-f0-9]{64}$/.test(source.BACKEND_IMAGE)
  ) {
    throw new Error("BACKEND_IMAGE must be an immutable registry digest");
  }
  if (!/^[a-f0-9]{40}$/.test(source.RELEASE_COMMIT))
    throw new Error("RELEASE_COMMIT must be a full Git SHA");
  try {
    const parsed = new URL(source.DATABASE_URL);
    if (
      !["postgres:", "postgresql:"].includes(parsed.protocol) ||
      !parsed.hostname ||
      !parsed.username ||
      !parsed.password ||
      parsed.pathname.length < 2
    )
      throw new Error();
  } catch {
    throw new Error(
      "DATABASE_URL must include PostgreSQL host, database and credentials",
    );
  }
  if (!/^(sk|rk)_live_/.test(source.STRIPE_SECRET_KEY))
    throw new Error("STRIPE_SECRET_KEY must be a live Stripe API key");
  if (!source.STRIPE_WEBHOOK_SECRET.startsWith("whsec_"))
    throw new Error(
      "STRIPE_WEBHOOK_SECRET must be a Stripe webhook signing secret",
    );

  const values = {
    NODE_ENV: "production",
    DOCKER_USERNAME: source.DOCKER_USERNAME || "",
  };
  for (const name of [...required, ...optional]) {
    const value = source[name] || "";
    if (value.includes("\0"))
      throw new Error(`Unsupported control character in ${name}`);
    values[name] = value;
  }
  // JSON-style double quotes preserve quotes/backslashes/newlines; doubling $
  // protects it from Compose interpolation, including after a backslash.
  // Never source this file in a shell or print `docker compose config` output.
  return (
    Object.entries(values)
      .map(
        ([name, value]) =>
          `${name}=${JSON.stringify(value.replace(/\$/g, () => "$$"))}`,
      )
      .join("\n") + "\n"
  );
}

if (require.main === module) {
  try {
    const destination = process.argv[2];
    if (!destination)
      throw new Error("Pass a new candidate environment-file path");
    const content = createProductionEnvironment(process.env);
    fs.writeFileSync(destination, content, { mode: 0o600, flag: "wx" });
    console.log(
      "Validated production configuration written to a new candidate file.",
    );
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}

module.exports = { createProductionEnvironment };
