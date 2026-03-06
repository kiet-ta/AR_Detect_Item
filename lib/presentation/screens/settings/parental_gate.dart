import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shows a simple arithmetic challenge (a + b = ?).
/// [onPassed] is called when the user enters the correct answer.
/// [onDismissed] is called when the user cancels.
Future<bool> showParentalGate(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ParentalGateDialog(),
      ) ??
      false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  final _rng = math.Random();
  late int _a;
  late int _b;
  late int _answer;
  final _ctrl = TextEditingController();
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _a = _rng.nextInt(9) + 1;
    _b = _rng.nextInt(9) + 1;
    _answer = _a + _b;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _check() {
    final input = int.tryParse(_ctrl.text);
    if (input == _answer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = true);
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      title: const Icon(Icons.lock_rounded,
          size: 40, color: AppColors.primary),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_a + $_b = ?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Answer',
              errorText: _error ? 'Try again' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (_) => _check(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _check,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
