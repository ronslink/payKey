import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// MAIN
// =============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PayKeyApp()));
}

// =============================================================================
// APP
// =============================================================================

class PayKeyApp extends ConsumerWidget {
  const PayKeyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const AppStatusPage(),
    );
  }
}

// =============================================================================
// CONFIG
// =============================================================================

abstract class AppConfig {
  static const String appName = 'PayKey';
  static const String tagline = 'Payroll and Tax Management System';
  static const String version = '1.0.0';
}

// =============================================================================
// THEME
// =============================================================================

abstract class AppTheme {
  static const _seedColor = Colors.deepPurple;

  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static final dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}

// =============================================================================
// COLORS
// =============================================================================

abstract class _AppColors {
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);
  static const textSecondary = Color(0xFF6B7280);
}

// =============================================================================
// STATUS PAGE
// =============================================================================

class AppStatusPage extends StatelessWidget {
  const AppStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
            tooltip: 'About',
          ),
        ],
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 40),
              _AppLogo(),
              SizedBox(height: 32),
              _AppTitle(),
              SizedBox(height: 8),
              _AppTagline(),
              SizedBox(height: 40),
              _StatusChecklist(),
              SizedBox(height: 40),
              _VersionInfo(),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: AppConfig.version,
      applicationLegalese: '© 2025 PayKey',
      children: [
        const SizedBox(height: 16),
        const Text(AppConfig.tagline),
      ],
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'PK',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '${AppConfig.appName} Mobile App',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _AppTagline extends StatelessWidget {
  const _AppTagline();

  @override
  Widget build(BuildContext context) {
    return const Text(
      AppConfig.tagline,
      style: TextStyle(
        fontSize: 16,
        color: _AppColors.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _VersionInfo extends StatelessWidget {
  const _VersionInfo();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Version ${AppConfig.version}',
      style: const TextStyle(
        fontSize: 12,
        color: _AppColors.textSecondary,
      ),
    );
  }
}

// =============================================================================
// STATUS CHECKLIST
// =============================================================================

/// Status item configuration.
enum StatusState { success, warning, error, pending }

class StatusItem {
  final String label;
  final StatusState state;
  final String? detail;

  const StatusItem({
    required this.label,
    required this.state,
    this.detail,
  });
}

/// Current system status items.
const List<StatusItem> _statusItems = [
  StatusItem(
    label: 'Backend Integrated',
    state: StatusState.success,
    detail: 'API connected',
  ),
  StatusItem(
    label: 'Tax Accumulation Active',
    state: StatusState.success,
    detail: 'PAYE, NHIF, NSSF, Housing Levy',
  ),
  StatusItem(
    label: 'Mobile App Compiled',
    state: StatusState.success,
    detail: 'Release build ready',
  ),
  StatusItem(
    label: 'M-Pesa Integration',
    state: StatusState.success,
    detail: 'Payments enabled',
  ),
  StatusItem(
    label: 'Push Notifications',
    state: StatusState.success,
    detail: 'Firebase configured',
  ),
];

class _StatusChecklist extends StatelessWidget {
  const _StatusChecklist();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._statusItems.map((item) => _StatusRow(item: item)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final StatusItem item;

  const _StatusRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final (icon, color, bgColor) = _getStatusVisuals(item.state);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.detail != null)
                  Text(
                    item.detail!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color) _getStatusVisuals(StatusState state) {
    return switch (state) {
      StatusState.success => (
          Icons.check_circle,
          _AppColors.success,
          _AppColors.successLight,
        ),
      StatusState.warning => (
          Icons.warning_rounded,
          _AppColors.warning,
          _AppColors.warningLight,
        ),
      StatusState.error => (
          Icons.error,
          _AppColors.error,
          _AppColors.errorLight,
        ),
      StatusState.pending => (
          Icons.hourglass_empty,
          _AppColors.info,
          _AppColors.infoLight,
        ),
    };
  }
}

// =============================================================================
// OPTIONAL: ANIMATED VERSION
// =============================================================================

/// Animated status page with staggered item appearance.
class AnimatedAppStatusPage extends StatefulWidget {
  const AnimatedAppStatusPage({super.key});

  @override
  State<AnimatedAppStatusPage> createState() => _AnimatedAppStatusPageState();
}

class _AnimatedAppStatusPageState extends State<AnimatedAppStatusPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  _AppLogo(),
                  SizedBox(height: 32),
                  _AppTitle(),
                  SizedBox(height: 8),
                  _AppTagline(),
                  SizedBox(height: 40),
                  _AnimatedStatusChecklist(),
                  SizedBox(height: 40),
                  _VersionInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStatusChecklist extends StatefulWidget {
  const _AnimatedStatusChecklist();

  @override
  State<_AnimatedStatusChecklist> createState() =>
      _AnimatedStatusChecklistState();
}

class _AnimatedStatusChecklistState extends State<_AnimatedStatusChecklist> {
  final List<bool> _visible = List.filled(_statusItems.length, false);

  @override
  void initState() {
    super.initState();
    _animateItems();
  }

  Future<void> _animateItems() async {
    for (int i = 0; i < _statusItems.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() => _visible[i] = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_statusItems.length, (index) {
            return AnimatedOpacity(
              opacity: _visible[index] ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedSlide(
                offset: _visible[index] ? Offset.zero : const Offset(0.1, 0),
                duration: const Duration(milliseconds: 300),
                child: _StatusRow(item: _statusItems[index]),
              ),
            );
          }),
        ],
      ),
    );
  }
}