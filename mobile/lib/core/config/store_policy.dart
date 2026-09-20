import 'package:flutter/foundation.dart';

/// App Store purchase policy.
///
/// On iOS, digital subscriptions must be sold through Apple In-App Purchase
/// (App Store Review Guideline 3.1.1). PayDome sells plans on the web and on
/// Android only, so the iOS app shows the user's current plan but offers no
/// way to buy, upgrade, or link to an external purchase.
class StorePolicy {
  StorePolicy._();

  /// Whether the app may show purchase / upgrade entry points.
  static bool get purchasesAllowed =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;
}
