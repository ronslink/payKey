import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/workers/presentation/pages/workers_list_page.dart';
import 'features/workers/presentation/pages/worker_form_page.dart';
import 'features/workers/data/models/worker_model.dart';
import 'features/payments/presentation/pages/topup_page.dart';
import 'features/payments/presentation/pages/transactions_page.dart';
import 'features/payments/presentation/pages/payments_page.dart';
import 'features/payments/presentation/pages/payment_detail_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/payroll/presentation/pages/payroll_page.dart';
import 'features/payroll/presentation/pages/run_payroll_page.dart';
import 'features/payroll/presentation/pages/payslip_page.dart';
import 'features/payroll/presentation/pages/payroll_review_page.dart';
import 'features/payroll/presentation/pages/payroll_confirm_page.dart';
import 'features/finance/presentation/pages/finance_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/subscriptions/presentation/pages/pricing_page.dart';
import 'features/time_tracking/presentation/pages/time_tracking_page.dart';
import 'features/time_tracking/presentation/pages/time_tracking_history_page.dart';
import 'features/workers/presentation/pages/terminate_worker_page.dart';
import 'features/workers/presentation/pages/archived_workers_page.dart';
import 'features/workers/presentation/pages/worker_detail_page.dart';
import 'features/properties/presentation/pages/properties_page.dart';
import 'features/properties/presentation/pages/property_form_page.dart';
import 'features/properties/presentation/pages/property_detail_page.dart';
import 'features/taxes/presentation/pages/comprehensive_tax_page.dart';
import 'main_layout.dart';
import 'core/network/api_service.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      // Simple redirect logic without async token checking to avoid interference
      final currentPath = state.matchedLocation;
      final isLoggingIn = currentPath == '/login' || currentPath == '/register';
      
      // Only redirect to login if we're not on auth pages and no token check
      // This prevents multiple requests during login process
      return null; // Let authentication be handled by providers
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Main app routes with tabbed layout
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayout(
          child: HomePage(),
          currentIndex: 0,
        ),
      ),
      GoRoute(
        path: '/workers',
        builder: (context, state) => const MainLayout(
          child: WorkersListPage(),
          currentIndex: 1,
        ),
      ),
      GoRoute(
        path: '/time-tracking',
        builder: (context, state) => const MainLayout(
          child: TimeTrackingPage(),
          currentIndex: 2,
        ),
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const MainLayout(
          child: PaymentsPage(),
          currentIndex: 3,
        ),
      ),
      GoRoute(
        path: '/tax',
        builder: (context, state) => const MainLayout(
          child: TaxPage(),
          currentIndex: 4,
        ),
      ),
      GoRoute(
        path: '/pricing',
        builder: (context, state) => const MainLayout(
          child: PricingPage(),
          currentIndex: 5,
        ),
      ),
      
      // Payment detail route
      GoRoute(
        path: '/payments/:id',
        builder: (context, state) {
          final transactionId = state.pathParameters['id']!;
          return PaymentDetailPage(transactionId: transactionId);
        },
      ),
      
      // Payroll Routes
      GoRoute(
        path: '/payroll',
        builder: (context, state) => const PayrollPage(),
      ),
      GoRoute(
        path: '/payroll/run/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RunPayrollPage(payPeriodId: id);
        },
      ),
      GoRoute(
        path: '/payroll/payslip/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PayslipPage(payslipId: id);
        },
      ),
      GoRoute(
        path: '/finance',
        builder: (context, state) => const FinancePage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      
      // Workers sub-routes
      GoRoute(
        path: '/workers/add',
        builder: (context, state) => const WorkerFormPage(),
      ),
      GoRoute(
        path: '/workers/:id',
        builder: (context, state) {
          final workerId = state.pathParameters['id']!;
          return WorkerDetailPage(workerId: workerId);
        },
      ),
      GoRoute(
        path: '/workers/:id/edit',
        builder: (context, state) {
          final worker = state.extra as WorkerModel?;
          return WorkerFormPage(worker: worker);
        },
      ),
      GoRoute(
        path: '/workers/:id/terminate',
        builder: (context, state) {
          final workerId = state.pathParameters['id']!;
          return TerminateWorkerPage(workerId: workerId);
        },
      ),
      GoRoute(
        path: '/workers/archived',
        builder: (context, state) => const ArchivedWorkersPage(),
      ),
      GoRoute(
        path: '/time-tracking/history',
        builder: (context, state) => const TimeTrackingHistoryPage(),
      ),
      // Properties Routes
      GoRoute(
        path: '/properties',
        builder: (context, state) => const PropertiesPage(),
      ),
      GoRoute(
        path: '/properties/add',
        builder: (context, state) => const PropertyFormPage(),
      ),
      GoRoute(
        path: '/properties/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return PropertyFormPage(propertyId: id);
        },
      ),
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailPage(propertyId: id);
        },
      ),
      GoRoute(
        path: '/taxes',
        builder: (context, state) => const ComprehensiveTaxPage(),
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PayKey',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class TaxPage extends StatelessWidget {
  const TaxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text(
          'Tax',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt,
                size: 40,
                color: Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tax Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tax filing and management coming soon',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


