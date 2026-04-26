import 'package:go_router/go_router.dart';

import '../../features/user/presentation/pages/users_page.dart';

final appRouter = GoRouter(
  initialLocation: '/users',
  routes: [
    GoRoute(path: '/users', builder: (context, state) => const UsersPage()),
  ],
);
