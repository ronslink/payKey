import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/workers/presentation/pages/workers_list_page.dart';
import 'features/workers/presentation/pages/worker_form_page.dart';
import 'features/workers/data/models/worker_model.dart';
import 'features/payroll/presentation/pages/run_payroll_page.dart';
import 'features/payroll/presentation/pages/payslip_page.dart';
import 'features/finance/presentation/pages/finance_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/subscriptions/presentation/pages/subscription_management_page.dart';
import 'features/payroll/presentation/pages/payroll_page.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(const ProviderScope(child: MyApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final currentPath = state.matchedLocation;
      final isAuthPage = currentPath == '/login' || currentPath == '/register';
      
      // Check if user is authenticated by looking for token
      // This helps prevent authenticated users from staying on login page
      final apiService = ApiService();
      final token = await apiService.getToken();
      
      // If user is authenticated and trying to access auth pages, redirect to home
      if (token != null && isAuthPage) {
        return '/home';
      }
      
      // Let the authentication be handled by providers
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
          currentIndex: 0,
          child: HomePage(),
        ),
      ),
      GoRoute(
        path: '/workers',
        builder: (context, state) => const MainLayout(
          currentIndex: 1,
          child: WorkersListPage(),
        ),
      ),
      GoRoute(
        path: '/time-tracking',
        builder: (context, state) => const MainLayout(
          currentIndex: 2,
          child: TimeTrackingPage(),
        ),
      ),
      GoRoute(
        path: '/tax',
        builder: (context, state) => const MainLayout(
          currentIndex: 4,
          child: TaxPage(),
        ),
      ),
      GoRoute(
        path: '/subscriptions',
        builder: (context, state) => const MainLayout(
          currentIndex: 3,
          child: SubscriptionManagementPage(),
        ),
      ),
      GoRoute(
        path: '/payroll',
        builder: (context, state) => const MainLayout(
          currentIndex: 5,
          child: PayrollPage(),
        ),
      ),
      // Payroll Routes (sub-routes for payroll management)
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
    return const Scaffold(
      body: ComprehensiveTaxPage(),
    );
  }
}


