import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sending_base_test/feature/pdf/text_save_pdf.dart';
import 'package:sending_base_test/feature/pdf/write_save_paf.dart';
import 'package:sending_base_test/routing/router_utils.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.textSavePdf.path,
    routes: [
      GoRoute(
        path: AppRoute.textSavePdf.path,
        name: AppRoute.textSavePdf.name,
        builder: (context, state) {
          return const TextSavePdf();
        },
        routes: [
          GoRoute(
            path: AppRoute.writeSavePdf.path,
            name: AppRoute.writeSavePdf.name,
            builder: (context, state) {
              return WriteSavePaf();
            },
          ),
        ],
      ),
    ],
  );
}
