import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/helpers/preferences_helper.dart';
import '../core/constants/route_names.dart';
import 'route_config.dart';

final appRouterProvider = FutureProvider<GoRouter>((ref) async {
  final isFirstLaunch = await PreferencesHelper.isFirstLaunch();
  
  return GoRouter(
    initialLocation: isFirstLaunch ? RouteNames.onboarding : RouteNames.transactions,
    routes: RouteConfig.getRoutes(),
  );
});

