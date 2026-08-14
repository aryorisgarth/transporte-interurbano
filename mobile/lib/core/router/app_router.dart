import 'package:go_router/go_router.dart';



import '../auth/auth_provider.dart';

import '../auth/jwt_utils.dart';

import '../../features/admin/presentation/admin_dashboard_page.dart';

import '../../features/auth/presentation/forbidden_page.dart';

import '../../features/auth/presentation/login_page.dart';

import '../../features/cajero/presentation/cajero_pasajeros_page.dart';

import '../../features/cajero/presentation/cajero_shell.dart';

import '../../features/cajero/presentation/cajero_venta_page.dart';

import '../../features/cajero/presentation/cajero_viajes_page.dart';

import '../../features/consulta/presentation/consulta_page.dart';

import '../../features/consulta/presentation/detalle_viaje_page.dart';

import '../../features/consulta/presentation/landing_page.dart';

import '../../features/consulta/presentation/not_found_page.dart';

import '../../shared/layout/public_scaffold.dart';



class AppRouter {

  static GoRouter create(AuthProvider auth) {

    return GoRouter(

      initialLocation: '/',

      refreshListenable: auth,

      redirect: (context, state) {

        final path = state.uri.path;

        final loggedIn = auth.isAuthenticated;



        if (path == '/acceso') return '/acceso/login';



        if (path.startsWith('/cajero')) {

          if (!loggedIn) return '/acceso/login?from=${Uri.encodeComponent(path)}';

          if (!puedeUsarPanelCajero(auth.roles) && !isAdmin(auth.roles)) {

            return loggedIn ? '/acceso/denegado' : '/acceso/login';

          }

        }



        if (path.startsWith('/admin')) {

          if (!loggedIn) return '/acceso/login?from=${Uri.encodeComponent(path)}';

          if (!isAdmin(auth.roles)) {

            if (puedeUsarPanelCajero(auth.roles)) return '/cajero';

            return loggedIn ? '/acceso/denegado' : '/acceso/login';

          }

        }



        if (loggedIn && path == '/acceso/login') {

          return rutaInicio(auth.roles, from: state.uri.queryParameters['from']);

        }



        return null;

      },

      routes: [

        ShellRoute(

          builder: (context, state, child) => PublicScaffold(child: child),

          routes: [

            GoRoute(path: '/', builder: (_, __) => const LandingPage()),

            GoRoute(path: '/consulta', builder: (_, __) => const ConsultaPage()),

            GoRoute(

              path: '/consulta/viaje/:id',

              builder: (_, state) => DetalleViajePage(viajeId: int.parse(state.pathParameters['id']!)),

            ),

            GoRoute(

              path: '/viaje/:id',

              redirect: (_, state) => '/consulta/viaje/${state.pathParameters['id']}',

            ),

            GoRoute(

              path: '/acceso/login',

              builder: (_, state) => LoginPage(redirectFrom: state.uri.queryParameters['from']),

            ),

            GoRoute(path: '/acceso/denegado', builder: (_, __) => const ForbiddenPage()),

          ],

        ),

        ShellRoute(

          builder: (context, state, child) => CajeroShell(child: child),

          routes: [

            GoRoute(path: '/cajero', builder: (_, __) => const CajeroViajesPage()),

            GoRoute(path: '/cajero/pasajeros', builder: (_, __) => const CajeroPasajerosPage()),

            GoRoute(

              path: '/cajero/venta/:id',

              builder: (_, state) => CajeroVentaPage(viajeId: int.parse(state.pathParameters['id']!)),

            ),

          ],

        ),

        GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardPage()),

        GoRoute(

          path: '/:path(.*)',

          builder: (_, __) => const PublicScaffold(child: NotFoundPage()),

        ),

      ],

    );

  }

}


