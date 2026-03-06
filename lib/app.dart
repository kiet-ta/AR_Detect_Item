import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/theme/app_theme.dart';
import 'presentation/bloc/sync/sync_bloc.dart';
import 'presentation/routes/app_router.dart';

/// Root widget of the Magic Doodle application.
/// Provides global BLoC instances and configures routing/theming.
class MagicDoodleApp extends StatelessWidget {
  const MagicDoodleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // SyncBloc runs globally to monitor connectivity and upload queue.
        BlocProvider<SyncBloc>(
          create: (_) => GetIt.I<SyncBloc>()..add(const SyncStartMonitoring()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Magic Doodle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
