# Subscription Dashboard Enhancement

## Overview

This document describes the enhancements made to the subscription page on the admin console, including a comprehensive dashboard, promotional items management, and campaign management functionality.

## Features Implemented

### 1. Subscription Dashboard

The subscription dashboard provides administrators with real-time insights into subscription metrics:

- **Overview Statistics:**
  - Total Subscriptions
  - Active Subscriptions
  - New Subscriptions (30 days)
  - New Subscriptions (7 days)
  - Churn Rate (30 days)
  - Monthly vs Yearly Billing breakdown

- **Tier Breakdown:**
  - Active subscribers per tier (FREE, BASIC, GOLD, PLATINUM)
  - Average workers per subscriber
  - Monthly Recurring Revenue (MRR) by tier

### 2. Promotional Items Management

Administrators can create and manage promotional items to drive user engagement:

- **Promotional Item Types:**
  - `DISCOUNT` - Percentage or fixed amount discounts
  - `FREE_TRIAL` - Free trial days
  - `FEATURE_UNLOCK` - Unlock specific features
  - `CREDIT` - Account credit

- **Management Features:**
  - Create, edit, and delete promotional items
  - Set validity periods (from/until dates)
  - Configure usage limits (max uses)
  - Target specific subscription tiers
  - Define terms and conditions
  - Track current usage

- **Status Management:**
  - DRAFT - Not yet active
  - ACTIVE - Currently available
  - PAUSED - Temporarily suspended
  - EXPIRED - No longer valid

### 3. Campaign Management

Administrators can create marketing campaigns that appear on the user console:

- **Campaign Types:**
  - `BANNER` - Top banner on user console
  - `POPUP` - Modal popup
  - `EMAIL` - Email campaigns
  - `IN_APP_NOTIFICATION` - In-app notifications
  - `SIDEBAR` - Sidebar promotions

- **Campaign Features:**
  - Create, edit, and delete campaigns
  - Schedule campaigns with start/end dates
  - Set campaign priority
  - Target specific user segments (tiers, countries)
  - Link to promotional items
  - Configure display settings (position, dismissible, auto-hide)

- **Performance Tracking:**
  - Impressions count
  - Clicks count
  - Conversions count

- **Status Management:**
  - DRAFT - Not yet published
  - SCHEDULED - Scheduled for future
  - ACTIVE - Currently running
  - PAUSED - Temporarily paused
  - COMPLETED - Finished
  - CANCELLED - Cancelled

## Backend Implementation

### New Entities

#### PromotionalItem Entity
Located at: `backend/src/modules/subscriptions/entities/promotional-item.entity.ts`

Fields:
- `id` - UUID primary key
- `name` - Promotional item name
- `description` - Description
- `type` - PromoItemType enum
- `status` - PromoStatus enum
- `discountPercentage` - Percentage discount
- `discountAmount` - Fixed amount discount
- `freeTrialDays` - Free trial duration
- `features` - JSON array of features
- `maxUses` - Maximum usage limit
- `currentUses` - Current usage count
- `validFrom` - Validity start date
- `validUntil` - Validity end date
- `applicableTiers` - Target subscription tiers
- `termsAndConditions` - Terms text
- `createdAt` - Creation timestamp
- `updatedAt` - Update timestamp

#### Campaign Entity
Located at: `backend/src/modules/subscriptions/entities/campaign.entity.ts`

Fields:
- `id` - UUID primary key
- `name` - Campaign name
- `description` - Description
- `type` - CampaignType enum
- `status` - CampaignStatus enum
- `title` - Campaign title
- `message` - Campaign message
- `callToAction` - CTA button text
- `callToActionUrl` - CTA link URL
- `imageUrl` - Campaign image URL
- `targetAudience` - JSON targeting config
- `scheduledFrom` - Start date
- `scheduledUntil` - End date
- `priority` - Campaign priority
- `impressions` - View count
- `clicks` - Click count
- `conversions` - Conversion count
- `promotionalItemId` - Linked promo item
- `displaySettings` - JSON display config
- `createdAt` - Creation timestamp
- `updatedAt` - Update timestamp

### API Endpoints

#### Subscription Dashboard
- `GET /api/admin/subscription-plans/dashboard` - Get comprehensive dashboard statistics

#### Promotional Items
- `GET /api/admin/subscription-plans/promotional-items` - List all promotional items
- `GET /api/admin/subscription-plans/promotional-items/:id` - Get single item
- `POST /api/admin/subscription-plans/promotional-items` - Create new item
- `PUT /api/admin/subscription-plans/promotional-items/:id` - Update item
- `DELETE /api/admin/subscription-plans/promotional-items/:id` - Delete item

#### Campaigns
- `GET /api/admin/subscription-plans/campaigns` - List all campaigns
- `GET /api/admin/subscription-plans/campaigns/:id` - Get single campaign
- `GET /api/admin/subscription-plans/campaigns/active` - Get active campaigns
- `POST /api/admin/subscription-plans/campaigns` - Create new campaign
- `PUT /api/admin/subscription-plans/campaigns/:id` - Update campaign
- `PUT /api/admin/subscription-plans/campaigns/:id/status` - Update campaign status
- `DELETE /api/admin/subscription-plans/campaigns/:id` - Delete campaign
- `POST /api/admin/subscription-plans/campaigns/:id/impression` - Track impression
- `POST /api/admin/subscription-plans/campaigns/:id/click` - Track click
- `POST /api/admin/subscription-plans/campaigns/:id/conversion` - Track conversion

### Database Migration

Migration file: `backend/src/migrations/add-promotional-items-and-campaigns.ts`

Creates:
- `promotional_items` table with indexes on status and validity period
- `campaigns` table with indexes on status, schedule, and priority
- Foreign key relationship from campaigns to promotional_items

## Frontend Implementation

### Admin Console Page

Located at: `admin/src/pages/SubscriptionPlansPage.tsx`

The page is organized into tabs:

1. **Subscription Plans** - Existing plan management with edit functionality
2. **Statistics** - Detailed subscription statistics by tier
3. **Promotional Items** - Full CRUD for promotional items
4. **Campaigns** - Full CRUD for campaigns with status management

### API Client Updates

Located at: `admin/src/api/client.ts`

Added:
- `adminPlans.dashboard()` - Get dashboard statistics
- `adminPromotionalItems` - All promotional item operations
- `adminCampaigns` - All campaign operations

## User Console Integration

To display campaigns on the user console, the following endpoints should be consumed:

### Get Active Campaigns
```
GET /api/admin/subscription-plans/campaigns/active
```

This returns all currently active campaigns that should be displayed to users.

### Track Campaign Interactions
```
POST /api/admin/subscription-plans/campaigns/:id/impression
POST /api/admin/subscription-plans/campaigns/:id/click
POST /api/admin/subscription-plans/campaigns/:id/conversion
```

These endpoints track user interactions with campaigns for analytics.

### Campaign Display Logic

When displaying campaigns on the user console:

1. Filter by `type` to determine display location (banner, popup, etc.)
2. Check `targetAudience` to match user's tier and other attributes
3. Respect `displaySettings` for positioning and behavior
4. Track impressions when displayed
5. Track clicks when user interacts
6. Track conversions when user completes the desired action

## Deployment Steps

1. Run the database migration:
   ```bash
   cd backend
   npm run migration:run
   ```

2. Restart the backend server to load new entities and endpoints

3. Build and deploy the admin console:
   ```bash
   cd admin
   npm run build
   ```

4. Access the subscription management page at `/subscriptions` in the admin console

## Security Considerations

- All promotional item and campaign endpoints require admin authentication
- Role-based access control (SUPER_ADMIN, ADMIN) for create/update/delete operations
- Audit logging for all promotional item and campaign changes
- Input validation on all endpoints

## Future Enhancements

Potential improvements for future iterations:

1. **A/B Testing** - Run multiple campaign variants
2. **Advanced Targeting** - More granular user segmentation
3. **Campaign Templates** - Pre-built campaign templates
4. **Analytics Dashboard** - Detailed campaign performance charts
5. **Automated Campaigns** - Trigger campaigns based on user behavior
6. **Promo Codes** - Generate unique promo codes for sharing
7. **Referral Program** - Track and reward user referrals
