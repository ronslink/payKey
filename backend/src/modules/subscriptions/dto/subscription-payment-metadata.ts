// Stored with a payment attempt; no entitlement changes until verified settlement.
export interface SubscriptionPaymentMetadata {
  [key: string]: unknown;
  planId?: string;
  targetTier?: string;
  reference?: string;
  promoId?: string;
  phoneNumber?: string;
  checkoutUrl?: string;
  renewal?: boolean;
  entitlementApplied?: boolean;
  intaSendInvoiceId?: string;
}

export function paymentMetadata(value: unknown): SubscriptionPaymentMetadata {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as SubscriptionPaymentMetadata)
    : {};
}
