import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/usage_log_entity.dart';
import '../../../domain/repositories/usage_log_repository.dart';
import '../../widgets/common/big_button.dart';

/// Shows queued failed drawings (Data Flywheel) in a 3-column grid.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  BigButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => context.pop(),
                    backgroundColor: AppColors.surface,
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(child: _DrawingGrid()),
          ],
        ),
      ),
    );
  }
}

class _DrawingGrid extends StatefulWidget {
  const _DrawingGrid();

  @override
  State<_DrawingGrid> createState() => _DrawingGridState();
}

class _DrawingGridState extends State<_DrawingGrid> {
  // Load queued drawings from local datasource.
  // Kept simple (no extra BLoC) — pure local data.
  late Future<Either<Failure, List<UsageLogEntity>>> _future;

  @override
  void initState() {
    super.initState();
    final repo = getIt<UsageLogRepository>();
    _future = repo.getLocalLogs();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Icon(Icons.error_outline));
        }
        return snapshot.data!.fold(
          (_) => const Center(child: Icon(Icons.error_outline)),
          (logs) {
            if (logs.isEmpty) {
              return Center(
                child: Icon(
                  Icons.inbox_rounded,
                  size: 80,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: logs.length,
              itemBuilder: (_, i) => Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      logs[i].sessionId.substring(0, 8),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
