/**
 * Seed Annual Campaigns
 *
 * Creates (or updates) the two recurring annual promotional campaigns:
 *   1. Christmas Campaign    — December 1–31 each year
 *   2. Mid-Year Campaign     — June 1–30 each year
 *
 * Each campaign consists of:
 *   - A PromotionalItem (the discount offer + promo code)
 *   - An EMAIL Campaign (server-dispatched by CampaignScheduler)
 *   - A BANNER Campaign (shown in-app via GET /subscriptions/campaigns/active)
 *
 * Usage:
 *   npx ts-node -r tsconfig-paths/register src/scripts/seed-annual-campaigns.ts
 *
 * Optional env overrides:
 *   CAMPAIGN_YEAR=2027   — override the year used in promo codes (default: current year)
 */

import 'reflect-metadata';
import { Client } from 'pg';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

// ── Config ────────────────────────────────────────────────────────────────────
const YEAR = parseInt(
  process.env.CAMPAIGN_YEAR || String(new Date().getFullYear()),
);

const dbConfig = process.env.DATABASE_URL
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    }
  : {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      user: process.env.DB_USERNAME || process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'Tina76',
      database: process.env.DB_NAME || 'paykey',
    };

// ── Campaign definitions ──────────────────────────────────────────────────────

const CAMPAIGNS = [
  {
    label: 'Christmas',
    promoCode: `XMAS${YEAR}`,
    promoName: `Christmas Upgrade Offer ${YEAR}`,
    promoDesc: `Festive season discount — ${YEAR}. 20% off any paid plan upgrade throughout December.`,
    discountPct: 20,
    validFrom: `${YEAR}-12-01T00:00:00Z`,
    validUntil: `${YEAR}-12-31T23:59:59Z`,
    terms: `Applies to first billing period of upgraded plan. One use per account. Cannot be combined with other offers. Valid Dec 1–31 ${YEAR}.`,
    emailTitle: `🎄 Happy Holidays! Upgrade to Gold — 20% off this December`,
    emailMsg: `It's the season of giving! As a PayDome employer, enjoy 20% off when you upgrade to Gold or Platinum this December. Unlock unlimited workers, automated payroll, and full compliance tools. Use code XMAS${YEAR} at checkout. Offer valid December 1–31.`,
    bannerTitle: `🎄 Festive Offer — 20% off upgrades!`,
    bannerMsg: `Upgrade to Gold or Platinum this December and save 20%. Use code XMAS${YEAR}.`,
    priority: 90,
  },
  {
    label: 'Mid-Year',
    promoCode: `MIDYEAR${YEAR}`,
    promoName: `Mid-Year Upgrade Offer ${YEAR}`,
    promoDesc: `Mid-year promotional discount — ${YEAR}. 15% off any paid plan upgrade throughout June.`,
    discountPct: 15,
    validFrom: `${YEAR}-06-01T00:00:00Z`,
    validUntil: `${YEAR}-06-30T23:59:59Z`,
    terms: `Applies to first billing period of upgraded plan. One use per account. Cannot be combined with other offers. Valid Jun 1–30 ${YEAR}.`,
    emailTitle: `☀️ Mid-Year Special — Upgrade to Gold and save 15%`,
    emailMsg: `We're halfway through ${YEAR} — a great time to power up your payroll! Enjoy 15% off when you upgrade to Gold or Platinum this June. Manage more workers, automate tax submissions, and run payroll in minutes. Use code MIDYEAR${YEAR} at checkout. Offer valid June 1–30.`,
    bannerTitle: `☀️ Mid-Year Deal — 15% off upgrades!`,
    bannerMsg: `Save 15% on Gold or Platinum this June. Use code MIDYEAR${YEAR}.`,
    priority: 85,
  },
];

// ── Seed logic ────────────────────────────────────────────────────────────────

async function seedAnnualCampaigns() {
  console.log(`\n🗓️  Seeding Annual Campaigns for ${YEAR}`);
  console.log('='.repeat(50));

  const client = new Client(dbConfig as any);
  await client.connect();
  console.log('✅ Database connected\n');

  try {
    for (const c of CAMPAIGNS) {
      console.log(`\n── ${c.label.toUpperCase()} CAMPAIGN (${c.promoCode}) ──`);

      // Upsert promo item
      const promoRes = await client.query(
        `INSERT INTO promotional_items (
            id, name, description, type, status,
            "promoCode", "discountPercentage", "discountAmount",
            "freeTrialDays", features, "maxUses", "currentUses",
            "validFrom", "validUntil", "applicableTiers",
            "termsAndConditions", "createdAt", "updatedAt"
          )
          VALUES (
            gen_random_uuid(), $1, $2, 'DISCOUNT', 'ACTIVE',
            $3, $4, NULL, NULL, NULL, NULL, 0,
            $5, $6, '["FREE","BASIC"]', $7, NOW(), NOW()
          )
          ON CONFLICT ("promoCode") DO UPDATE SET
            name = EXCLUDED.name,
            description = EXCLUDED.description,
            status = EXCLUDED.status,
            "discountPercentage" = EXCLUDED."discountPercentage",
            "validFrom" = EXCLUDED."validFrom",
            "validUntil" = EXCLUDED."validUntil",
            "termsAndConditions" = EXCLUDED."termsAndConditions",
            "updatedAt" = NOW()
          RETURNING id, "promoCode"`,
        [
          c.promoName,
          c.promoDesc,
          c.promoCode,
          c.discountPct,
          c.validFrom,
          c.validUntil,
          c.terms,
        ],
      );
      const promoId = promoRes.rows[0].id;
      const promoAction =
        promoRes.rowCount === 1 && promoRes.rows[0]
          ? '✅ Created'
          : '↺ Updated';
      console.log(`  ${promoAction} promo: ${c.promoCode} (id: ${promoId})`);

      // Helper to upsert a campaign
      const upsertCampaign = async (type: 'EMAIL' | 'BANNER') => {
        const name = `${YEAR} ${c.label} — ${type}`;
        const isEmail = type === 'EMAIL';
        const displaySettings = isEmail
          ? null
          : JSON.stringify({
              position: 'top',
              dismissible: true,
              autoHideAfter: null,
              showOnPages: ['dashboard', 'subscription'],
            });

        const existing = await client.query(
          `SELECT id FROM campaigns WHERE name = $1`,
          [name],
        );

        if (existing.rows.length > 0) {
          // Update but preserve lastDispatchedAt to avoid accidental re-sends
          await client.query(
            `UPDATE campaigns SET
              description = $1, status = 'ACTIVE', title = $2, message = $3,
              "callToAction" = $4, "callToActionUrl" = $5,
              "targetAudience" = '{"tiers":["FREE","BASIC"]}',
              "scheduledFrom" = $6, "scheduledUntil" = $7,
              priority = $8, "displaySettings" = $9::jsonb,
              "promotionalItemId" = $10, "updatedAt" = NOW()
            WHERE name = $11`,
            [
              `${c.label} ${YEAR} promotional campaign. ${isEmail ? 'Server-dispatched email.' : 'In-app banner.'}`,
              isEmail ? c.emailTitle : c.bannerTitle,
              isEmail ? c.emailMsg : c.bannerMsg,
              'Upgrade Now',
              '/subscription/upgrade',
              c.validFrom,
              c.validUntil,
              c.priority,
              displaySettings,
              promoId,
              name,
            ],
          );
          console.log(`  ↺ Updated ${type} campaign: "${name}"`);
        } else {
          await client.query(
            `INSERT INTO campaigns (
                id, name, description, type, status,
                title, message, "callToAction", "callToActionUrl",
                "imageUrl", "targetAudience",
                "scheduledFrom", "scheduledUntil",
                priority, impressions, clicks, conversions,
                "displaySettings", "promotionalItemId",
                "lastDispatchedAt", "lastDispatchCount",
                "createdAt", "updatedAt"
              ) VALUES (
                gen_random_uuid(), $1, $2, $3, 'ACTIVE',
                $4, $5, $6, $7,
                NULL, '{"tiers":["FREE","BASIC"]}',
                $8, $9,
                $10, 0, 0, 0,
                $11::jsonb, $12,
                NULL, 0,
                NOW(), NOW()
              )`,
            [
              name,
              `${c.label} ${YEAR} promotional campaign. ${isEmail ? 'Server-dispatched email.' : 'In-app banner.'}`,
              type,
              isEmail ? c.emailTitle : c.bannerTitle,
              isEmail ? c.emailMsg : c.bannerMsg,
              'Upgrade Now',
              '/subscription/upgrade',
              c.validFrom,
              c.validUntil,
              c.priority,
              displaySettings,
              promoId,
            ],
          );
          console.log(`  ✅ Created ${type} campaign: "${name}"`);
        }
      };

      await upsertCampaign('EMAIL');
      await upsertCampaign('BANNER');
    }

    console.log('\n✅ Annual campaigns seeded successfully.');
    console.log('\nNext steps:');
    console.log('  1. Verify in Admin → Subscription Management → Campaigns');
    console.log(
      '  2. EMAIL campaigns auto-dispatch within 15 min once scheduledFrom ≤ now',
    );
    console.log(
      '  3. BANNER campaigns appear in-app immediately when scheduledFrom ≤ now',
    );
    console.log(
      `  4. Promo codes active: XMAS${YEAR} (20% off, Dec), MIDYEAR${YEAR} (15% off, Jun)\n`,
    );
  } finally {
    await client.end();
  }
}

seedAnnualCampaigns().catch((err) => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
