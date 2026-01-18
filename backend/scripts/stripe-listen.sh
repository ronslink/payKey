#!/bin/bash

# This script helps you listen for Stripe webhooks in development.
# It forwards events from Stripe to your local NestJS backend.

echo "🚀 Starting Stripe Webhook Listener..."
echo "--------------------------------------------------"
echo "💡 TIP: Look for the 'whsec_...' key in the output below."
echo "💡 You must paste that key into your backend/.env as STRIPE_WEBHOOK_SECRET"
echo "--------------------------------------------------"

stripe listen --forward-to localhost:3000/payments/stripe/webhook
