/// IntaSend integration for PayKey
/// 
/// Clean M-Pesa integration via IntaSend for:
/// - STK Push (collect payments from employers)
/// - Payouts (disburse salaries to workers)
/// - Wallet management (check balance)
/// - Webhooks (receive payment notifications)

library;

// Config
export 'config/intasend_config.dart';
export 'config/intasend_webhook_config.dart';

// Models
export 'models/intasend_models.dart';

// Services
export 'services/intasend_service.dart';
export 'services/payment_service.dart';

// Providers
export 'providers/intasend_providers.dart';

// Webhooks
export 'webhooks/intasend_webhook_handler.dart';

// Widgets
export 'widgets/intasend_trust_badge.dart';
