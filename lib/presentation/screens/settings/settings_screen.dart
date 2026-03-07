import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/common/big_button.dart';
import 'parental_gate.dart';

/// Settings screen locked behind [showParentalGate].
/// Exposes: session timer duration, language toggle (EN/VI), debug mode.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _unlocked = false;
  bool _viEnabled = true;
  bool _debugMode = false;
  int _sessionMinutes = 15;

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    final passed = await showParentalGate(context);
    if (!mounted) return;
    if (passed) {
      setState(() => _unlocked = true);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const _SectionHeader(label: '⏱  Session Timer'),
                  _SessionSlider(
                    value: _sessionMinutes,
                    onChanged: (v) => setState(() => _sessionMinutes = v),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(label: '🇦🇺  Vietnamese Vocabulary'),
                  SwitchListTile(
                    value: _viEnabled,
                    onChanged: (v) => setState(() => _viEnabled = v),
                    title: const Text('Play Vietnamese after English'),
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(label: '🔧  Developer'),
                  SwitchListTile(
                    value: _debugMode,
                    onChanged: (v) => setState(() => _debugMode = v),
                    title: const Text('Show confidence indicator'),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SessionSlider extends StatelessWidget {
  const _SessionSlider({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            label: '$value min',
            onChanged: (v) => onChanged(v.round()),
            activeColor: AppColors.primary,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$value min',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
