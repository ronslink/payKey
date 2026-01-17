import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Features
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/workers/presentation/pages/worker_form_page.dart';
import 'features/workers/presentation/pages/worker_detail_page.dart';
import 'features/workers/presentation/pages/terminate_worker_page.dart';
import 'features/workers/presentation/pages/archived_workers_page.dart';
import 'features/workers/presentation/pages/workers_import_page.dart';
import 'features/workers/data/models/worker_model.dart';
import 'features/payroll/presentation/pages/payroll_page.dart';
import 'features/payroll/presentation/pages/run_payroll_page_new.dart';
import 'features/payroll/presentation/pages/payroll_review_page.dart';
import 'features/payroll/presentation/pages/payslip_page.dart';
import 'features/payroll/presentation/pages/payroll_confirm_page.dart';
import 'features/payroll/data/models/payroll_model.dart';

import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/subscriptions/presentation/pages/subscription_management_page.dart';
import 'features/subscriptions/presentation/pages/payment_page.dart';
import 'features/subscriptions/data/models/subscription_model.dart';
import 'features/time_tracking/presentation/pages/time_tracking_page.dart';
import 'features/time_tracking/presentation/pages/time_tracking_history_page.dart';
import 'features/properties/presentation/pages/properties_page.dart';
import 'features/properties/presentation/pages/property_form_page.dart';
import 'features/properties/presentation/pages/property_detail_page.dart';
import 'features/taxes/presentation/pages/comprehensive_tax_page.dart';
import 'features/reports/presentation/pages/reports_page.dart';
import 'features/employee_portal/presentation/pages/employee_login_page.dart';
import 'features/employee_portal/presentation/pages/employee_dashboard_page.dart';
import 'features/employee_portal/presentation/pages/request_leave_page.dart';
import 'features/employee_portal/presentation/pages/employee_p9_page.dart';
import 'features/employee_portal/presentation/pages/employee_my_leaves_page.dart';
import 'features/employee_portal/presentation/pages/employee_timesheet_page.dart';
import 'features/employee_portal/presentation/pages/employee_payslips_page.dart';
import 'features/employee_portal/presentation/pages/employee_payment_settings_page.dart';
import 'features/time_tracking/presentation/pages/attendance_dashboard_page.dart';
import 'features/leave_management/presentation/pages/leave_dashboard_page.dart';
import 'features/profile/presentation/pages/edit_profile_page.dart';

// Core
import 'core/network/api_service.dart';
import 'core/widgets/feature_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'main_layout_new.dart';

// New Pages
import 'features/home/presentation/pages/home_page.dart';
import 'features/workers/workers.dart';
import 'features/finance/finance.dart';
import 'features/finance/presentation/pages/mpesa_top_up_page.dart';
import 'features/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/storage_provider.dart';

// =============================================================================
// MAIN
// =============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  if (kIsWeb) {
    // On Web, minimize initialization or provide dummy options if necessary
    // await Firebase.initializeApp(options: ...);
    debugPrint('Firebase Web initialization skipped or needs options');
  } else {
    await Firebase.initializeApp();
    
    // Set up background message handler (Mobile only)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize notification service (Mobile only)
    await NotificationService().initialize();
  }
  
  // Initialize SharedPreferences for token storage
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  
  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storageService),
      ],
      child: const PaydomeApp(),
    ),
  );
}

// =============================================================================
// APP
// =============================================================================

class PaydomeApp extends ConsumerWidget {
  const PaydomeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

// =============================================================================
// APP CONFIG
// =============================================================================

abstract class AppConfig {
  static const String appName = 'payDome';
  static const String initialRoute = AppRoutes.login;
}


// =============================================================================
// ROUTES
// =============================================================================

/// Route path constants.
abstract class AppRoutes {
  // Auth
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';

  // Main tabs
  static const home = '/home';
  static const workers = '/workers';
  static const timeTracking = '/time-tracking';
  static const subscriptions = '/subscriptions';
  // tax route removed - using finance page
  static const payroll = '/payroll';
  static const finance = '/finance';
  static const settings = '/settings';
  static const settingsSubscription = '/settings/subscription';

  // Workers
  static const workersAdd = '/workers/add';
  static const workersArchived = '/workers/archived';
  static String workerDetail(String id) => '/workers/$id';
  static String workerEdit(String id) => '/workers/$id/edit';
  static String workerTerminate(String id) => '/workers/$id/terminate';

  // Payroll
  static const payrollRun = '/payroll/run';
  static String payrollRunWithId(String id) => '/payroll/run/$id';
  static String payrollReview(String id) => '/payroll/review/$id';
  static String payslip(String id) => '/payroll/payslip/$id';

  // Subscriptions
  static const subscriptionPayment = '/subscriptions/payment';

  // Time Tracking
  static const timeTrackingHistory = '/time-tracking/history';

  // Properties
  static const properties = '/properties';
  static const propertiesAdd = '/properties/add';
  static String propertyDetail(String id) => '/properties/$id';
  static String propertyEdit(String id) => '/properties/edit/$id';

  // Other
  static const taxes = '/taxes';
  static const accounting = '/accounting';
  static const reports = '/reports';
  // govSubmissions route removed - using ComprehensiveTaxPage
  static const attendance = '/attendance';
  static const leave = '/leave';
  static const profileEdit = '/profile/edit';

  // Employee Portal
  static const employeeLogin = '/employee/login';
  static const employeeDashboard = '/employee/dashboard';
  static const employeeRequestLeave = '/employee/request-leave';
  static const employeeMyLeaves = '/employee/my-leaves';
  static const employeeTimesheet = '/employee/timesheet';
  static const employeePayslips = '/employee/payslips';
  static const employeeP9 = '/employee/p9';
  static const employeePaymentSettings = '/employee/payment-settings';
}


// =============================================================================
// ROUTER PROVIDER
// =============================================================================

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConfig.initialRoute,
    redirect: _handleRedirect,
    routes: [
      ..._authRoutes,
      ..._mainTabRoutes,
      ..._workerRoutes,
      ..._payrollRoutes,
      ..._subscriptionRoutes,
      ..._timeTrackingRoutes,
      ..._propertyRoutes,
      ..._otherRoutes,
    ],
  );
});

// =============================================================================
// REDIRECT LOGIC
// =============================================================================

Future<String?> _handleRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  final currentPath = state.matchedLocation;
  final isAuthPage = _isAuthRoute(currentPath);

  // Check authentication status
  final token = await ApiService().getToken();
  final isAuthenticated = token != null;

  // Redirect authenticated users away from auth pages
  if (isAuthenticated && isAuthPage) {
    return AppRoutes.home;
  }

  // Let other navigation proceed normally
  // Auth protection for other routes is handled by providers
  return null;
}

bool _isAuthRoute(String path) {
  return path == AppRoutes.login || 
         path == AppRoutes.register ||
         path == AppRoutes.employeeLogin;
}

// =============================================================================
// ROUTE DEFINITIONS
// =============================================================================

// -----------------------------------------------------------------------------
// Auth Routes
// -----------------------------------------------------------------------------

final _authRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.login,
    name: 'login',
    builder: (_, _) => const LoginPage(),
  ),
  GoRoute(
    path: AppRoutes.register,
    name: 'register',
    builder: (_, _) => const RegisterPage(),
  ),
  GoRoute(
    path: AppRoutes.onboarding,
    name: 'onboarding',
    builder: (_, _) => const OnboardingPage(),
  ),
  // Employee Portal Auth
  GoRoute(
    path: AppRoutes.employeeLogin,
    name: 'employeeLogin',
    builder: (_, _) => const EmployeeLoginPage(),
  ),
];

// -----------------------------------------------------------------------------
// Main Tab Routes
// -----------------------------------------------------------------------------



final _mainTabRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.home,
    name: 'home',
    builder: (_, _) => const MainLayoutNew(
      currentIndex: 0,
      child: HomePage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.workers,
    name: 'workers',
    builder: (_, _) => const MainLayoutNew(
      currentIndex: 1,
      child: WorkersPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.timeTracking,
    name: 'timeTracking',
    builder: (_, _) => const FeatureGate(
      featureKey: 'time_tracking',
      child: TimeTrackingPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.subscriptions,
    name: 'subscriptions',
    builder: (_, _) => const SubscriptionManagementPage(),
  ),
  // TaxPageNew route removed - using finance page
  GoRoute(
    path: AppRoutes.payroll,
    name: 'payroll',
    builder: (_, _) => const MainLayoutNew(
      currentIndex: 2,
      child: PayrollPage(),
    ),
  ),
  GoRoute(
    path: '/payroll/run',
    name: 'runPayrollNew',
    builder: (_, _) => const RunPayrollPageNew(),
  ),
  GoRoute(
    path: AppRoutes.finance,
    name: 'finance',
    builder: (_, _) => const MainLayoutNew(
      currentIndex: 3,
      child: FinancePage(),
    ),
  ),
  GoRoute(
    path: '/finance/top-up',
    name: 'financeTopUp',
    builder: (_, _) => const MpesaTopUpPage(),
  ),
  GoRoute(
    path: AppRoutes.settings,
    name: 'settings',
    builder: (_, _) => const MainLayoutNew(
      currentIndex: 4,
      child: SettingsPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.settingsSubscription,
    name: 'settingsSubscription',
    builder: (_, _) => const SubscriptionManagementPage(),
  ),
];

// -----------------------------------------------------------------------------
// Worker Routes
// -----------------------------------------------------------------------------

final _workerRoutes = <RouteBase>[
  GoRoute(
    path: '/workers/import',
    name: 'workersImport',
    builder: (_, _) => const WorkersImportPage(),
  ),
  GoRoute(
    path: AppRoutes.workersAdd,
    name: 'workersAdd',
    builder: (_, _) => const WorkerFormPage(),
  ),
  GoRoute(
    path: AppRoutes.workersArchived,
    name: 'workersArchived',
    builder: (_, _) => const ArchivedWorkersPage(),
  ),
  GoRoute(
    path: '/workers/:id',
    name: 'workerDetail',
    builder: (_, state) {
      final workerId = state.pathParameters['id']!;
      return WorkerDetailPage(workerId: workerId);
    },
  ),
  GoRoute(
    path: '/workers/:id/edit',
    name: 'workerEdit',
    builder: (_, state) {
      final worker = state.extra as WorkerModel?;
      return WorkerFormPage(worker: worker);
    },
  ),
  GoRoute(
    path: '/workers/:id/terminate',
    name: 'workerTerminate',
    builder: (_, state) {
      final workerId = state.pathParameters['id']!;
      return TerminateWorkerPage(workerId: workerId);
    },
  ),

];

// -----------------------------------------------------------------------------
// Payroll Routes
// -----------------------------------------------------------------------------

final _payrollRoutes = <RouteBase>[

  GoRoute(
    path: '/payroll/run/:id',
    name: 'payrollRunWithId',
    builder: (_, state) {
      final id = state.pathParameters['id']!;
      return RunPayrollPageNew(payPeriodId: id);
    },
  ),
  GoRoute(
    path: '/payroll/review/:id',
    name: 'payrollReview',
    builder: (_, state) {
      final id = state.pathParameters['id']!;
      final selectedWorkers = state.extra as List<WorkerModel>? ?? [];
      return PayrollReviewPage(payPeriodId: id, selectedWorkers: selectedWorkers);
    },
  ),
  GoRoute(
    path: '/payroll/payslip/:id',
    name: 'payslip',
    builder: (_, state) {
      final id = state.pathParameters['id']!;
      final calculation = state.extra as PayrollCalculation?;
      return PayslipPage(payslipId: id, calculation: calculation);
    },
  ),
  GoRoute(
    path: '/payroll/confirm/:id',
    name: 'payrollConfirm',
    builder: (_, state) {
      final id = state.pathParameters['id']!;
      final extraData = state.extra;
      final workerIds = extraData is List 
          ? extraData.map((e) => e.toString()).toList()
          : <String>[];
      return PayrollConfirmPage(payPeriodId: id, workerIds: workerIds);
    },
  ),
];

// -----------------------------------------------------------------------------
// Subscription Routes
// -----------------------------------------------------------------------------

final _subscriptionRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.subscriptionPayment,
    name: 'subscriptionPayment',
    builder: (_, state) {
      final plan = state.extra as SubscriptionPlan;
      final returnPath = state.uri.queryParameters['returnPath'];
      return PaymentPage(plan: plan, returnPath: returnPath);
    },
  ),
];

// -----------------------------------------------------------------------------
// Time Tracking Routes
// -----------------------------------------------------------------------------

final _timeTrackingRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.timeTrackingHistory,
    name: 'timeTrackingHistory',
    builder: (_, _) => const FeatureGate(
      featureKey: 'time_tracking',
      child: TimeTrackingHistoryPage(),
    ),
  ),
];

// -----------------------------------------------------------------------------
// Property Routes
// -----------------------------------------------------------------------------

final _propertyRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.properties,
    name: 'properties',
    builder: (_, _) => const FeatureGate(
      featureKey: 'property_management',
      child: PropertiesPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.propertiesAdd,
    name: 'propertiesAdd',
    builder: (_, _) => const FeatureGate(
      featureKey: 'property_management',
      child: PropertyFormPage(),
    ),
  ),
  GoRoute(
    path: '/properties/edit/:id',
    name: 'propertyEdit',
    builder: (_, state) {
      final id = state.pathParameters['id'];
      return FeatureGate(
        featureKey: 'property_management',
        child: PropertyFormPage(propertyId: id),
      );
    },
  ),
  GoRoute(
    path: '/properties/:id',
    name: 'propertyDetail',
    builder: (_, state) {
      final id = state.pathParameters['id']!;
      return FeatureGate(
        featureKey: 'property_management',
        child: PropertyDetailPage(propertyId: id),
      );
    },
  ),
];

// -----------------------------------------------------------------------------
// Other Routes
// -----------------------------------------------------------------------------

final _otherRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.taxes,
    name: 'taxes',
    builder: (_, _) => const ComprehensiveTaxPage(),
  ),

  GoRoute(
    path: AppRoutes.reports,
    name: 'reports',
    builder: (_, _) => const FeatureGate(
      featureKey: 'basic_reports',
      child: ReportsPage(),
    ),
  ),
  // GovSubmissionsPage route removed - using ComprehensiveTaxPage
  // Attendance (for employers)
  GoRoute(
    path: AppRoutes.attendance,
    name: 'attendance',
    builder: (_, _) => const AttendanceDashboardPage(),
  ),
  GoRoute(
    path: AppRoutes.leave,
    name: 'leave',
    builder: (_, _) => const FeatureGate(
      featureKey: 'leave_management',
      child: LeaveDashboardPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.profileEdit,
    name: 'profileEdit',
    builder: (_, _) => const EditProfilePage(),
  ),
  // Employee Portal Routes
  GoRoute(
    path: AppRoutes.employeeDashboard,
    name: 'employeeDashboard',
    builder: (_, _) => const EmployeeDashboardPage(),
  ),
  GoRoute(
    path: AppRoutes.employeeRequestLeave,
    name: 'employeeRequestLeave',
    builder: (_, _) => const RequestLeavePage(),
  ),
  GoRoute(
    path: AppRoutes.employeeMyLeaves,
    name: 'employeeMyLeaves',
    builder: (_, _) => const EmployeeMyLeavesPage(),
  ),
  GoRoute(
    path: AppRoutes.employeeTimesheet,
    name: 'employeeTimesheet',
    builder: (_, _) => const EmployeeTimesheetPage(),
  ),
  GoRoute(
    path: AppRoutes.employeePayslips,
    name: 'employeePayslips',
    builder: (_, _) => const EmployeePayslipsPage(),
  ),
  GoRoute(
    path: AppRoutes.employeeP9,
    name: 'employeeP9',
    builder: (_, _) => const EmployeeP9Page(),
  ),
  GoRoute(
    path: AppRoutes.employeePaymentSettings,
    name: 'employeePaymentSettings',
    builder: (_, _) => const EmployeePaymentSettingsPage(),
  ),
];

// =============================================================================
// NAVIGATION EXTENSIONS
// =============================================================================

/// Extension methods for easier navigation.
extension NavigationExtensions on BuildContext {
  // Auth
  void goToLogin() => go(AppRoutes.login);
  void goToRegister() => go(AppRoutes.register);
  void goToOnboarding() => go(AppRoutes.onboarding);

  // Main tabs
  void goToHome() => go(AppRoutes.home);
  void goToWorkers() => go(AppRoutes.workers);
  void goToPayroll() => go(AppRoutes.payroll);
  void goToFinance() => go(AppRoutes.finance);

  // Workers
  void goToAddWorker() => go(AppRoutes.workersAdd);
  void goToWorkerDetail(String id) => go(AppRoutes.workerDetail(id));
  void pushWorkerEdit(String id, WorkerModel? worker) {
    push(AppRoutes.workerEdit(id), extra: worker);
  }
  void pushWorkerTerminate(String id) => push(AppRoutes.workerTerminate(id));

  // Payroll
  void goToRunPayroll([String? periodId]) {
    if (periodId != null) {
      go(AppRoutes.payrollRunWithId(periodId));
    } else {
      go(AppRoutes.payrollRun);
    }
  }
  void pushPayrollReview(String id) => push(AppRoutes.payrollReview(id));
  void pushPayslip(String id) => push(AppRoutes.payslip(id));

  // Subscriptions
  void pushSubscriptionPayment(SubscriptionPlan plan) {
    push(AppRoutes.subscriptionPayment, extra: plan);
  }

  // Properties
  void goToProperties() => go(AppRoutes.properties);
  void goToAddProperty() => go(AppRoutes.propertiesAdd);
  void goToPropertyDetail(String id) => go(AppRoutes.propertyDetail(id));
  void goToPropertyEdit(String id) => go(AppRoutes.propertyEdit(id));
}