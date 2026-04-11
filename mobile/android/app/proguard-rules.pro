# Stripe configuration - allow missing references
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }

# React Native Stripe SDK - ignore missing classes
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**

# Additional Stripe rules to handle missing classes
-dontwarn com.stripe.android.**
-keep class com.stripe.android.** { *; }

# Flutter Stripe
-keep class flutter_stripe.** { *; }
-dontwarn flutter_stripe.**

# General rules to prevent R8 from failing on missing classes
-ignorewarnings
-allowaccessmodification
-dontobfuscate
