import 'package:go_router/go_router.dart';

import 'package:flutter_bloc_clean_architecture_template/features/example/presentation/pages/home_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
