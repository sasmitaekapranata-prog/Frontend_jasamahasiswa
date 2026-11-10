import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import Route Names
import 'route_names.dart';

// Import Core
import 'package:jasa_mahasiswa/core/widgets/main_shell_layout.dart';

// Import Auth Screens
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';

// Import Dashboard Screens
import '../../features/dashboard/presentation/beranda_screen.dart';
import '../../features/dashboard/presentation/chat_screen.dart';
import '../../features/dashboard/presentation/chat_detail_screen.dart';
import '../../features/dashboard/presentation/service_detail_screen.dart';
import '../../features/dashboard/presentation/seller_profile_screen.dart';
import '../../features/dashboard/presentation/order_checkout_screen.dart';
import '../../features/dashboard/presentation/payment_screen.dart';
import '../../features/dashboard/presentation/service_catalog.dart';
import '../../features/dashboard/presentation/order_payment.dart';
import '../../features/dashboard/presentation/payment_success_screen.dart';

// Import Profile Main Screen & Detail Screens
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/screens/create_service_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/help_center_screen.dart';
import '../../features/profile/presentation/screens/incoming_orders_screen.dart';
import '../../features/profile/presentation/screens/manage_services_screen.dart';
import '../../features/profile/presentation/screens/status_pesanan_screen.dart';
import '../../features/profile/presentation/screens/withdraw_saldo_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.landing,
    routes: [
      // 1. AUTHENTICATION (FULLSCREEN)
      GoRoute(
        path: Routes.landing,
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // 2. MAIN SHELL (MEMILIKI BOTTOM NAVIGATION BAR)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShellLayout(child: child);
        },
        routes: [
          GoRoute(
            path: Routes.beranda,
            builder: (context, state) => const BerandaScreen(),
          ),
          GoRoute(
            path: Routes.chat,
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: Routes.profil,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // 3. DETAIL SCREENS (FULLSCREEN / TANPA BOTTOM BAR)
      GoRoute(
        path: '${Routes.serviceDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return ServiceDetailScreen(serviceId: id);
        },
      ),
      GoRoute(
        path: '${Routes.sellerProfile}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return SellerProfileScreen(serviceId: id);
        },
      ),
      GoRoute(
        path: Routes.orderCheckout,
        builder: (context, state) => OrderCheckoutScreen(
          service:
              state.extra is ServiceInfo ? state.extra as ServiceInfo : null,
        ),
      ),
      GoRoute(
        path: Routes.qrisPayment,
        builder: (context, state) => PaymentScreen(
          payment:
              state.extra is OrderPayment ? state.extra as OrderPayment : null,
        ),
      ),
      GoRoute(
        path: Routes.paymentSuccess,
        builder: (context, state) => PaymentSuccessScreen(
          payment:
              state.extra is OrderPayment ? state.extra as OrderPayment : null,
        ),
      ),
      GoRoute(
        path: Routes.createService,
        builder: (context, state) => const CreateServiceScreen(),
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (context, state) => EditProfileScreen(
          isSeller: state.extra == true,
        ),
      ),
      GoRoute(
        path: Routes.incomingOrders,
        builder: (context, state) => const IncomingOrdersScreen(),
      ),
      GoRoute(
        path: Routes.manageServices,
        builder: (context, state) => const ManageServicesScreen(),
      ),
      GoRoute(
        path: Routes.statusPesanan,
        builder: (context, state) => const StatusPesananScreen(),
      ),
      GoRoute(
        path: Routes.helpCenter,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '${Routes.chatDetail}/:id',
        builder: (context, state) => ChatDetailScreen(
          chatId: state.pathParameters['id'],
          order:
              state.extra is OrderPayment ? state.extra as OrderPayment : null,
        ),
      ),
      GoRoute(
        path: Routes.withdrawSaldo,
        builder: (context, state) => const WithdrawSaldoScreen(),
      ),
    ],
  );
}
