import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/public_mode_models.dart';

/// Shows a refined, custom PIN pad dialog to set and confirm a 4-digit PIN.
/// If the device has no lock screen, it prompts for an optional secret recovery word.
Future<bool> showPublicModePinSetupDialog(
  BuildContext context, {
  required PublicModeRepository repository,
  required void Function(String pin, String? recoveryAnswer) onSaved,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (modalCtx) => _PinSetupSheet(
      repository: repository,
      onSaved: onSaved,
    ),
  );
  return result ?? false;
}

/// Shows a refined, custom PIN pad dialog to verify the exit PIN.
/// If the user forgets the PIN:
/// - Authenticates via device lock (fingerprint/face/pattern) if device is secure.
/// - Prompts for secret recovery answer if no device lock is set.
Future<bool> showPublicModePinVerifyDialog(
  BuildContext context, {
  required String expectedPin,
  String? recoveryAnswer,
  int endsAt = 0,
  required Future<void> Function() onVerified,
  required PublicModeRepository repository,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (modalCtx) => _PinVerifySheet(
      expectedPin: expectedPin,
      recoveryAnswer: recoveryAnswer,
      endsAt: endsAt,
      onVerified: onVerified,
      repository: repository,
    ),
  );
  return result ?? false;
}

class _PinSetupSheet extends StatefulWidget {
  const _PinSetupSheet({
    required this.repository,
    required this.onSaved,
  });

  final PublicModeRepository repository;
  final void Function(String pin, String? recoveryAnswer) onSaved;

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet>
    with SingleTickerProviderStateMixin {
  String _firstPin = '';
  String _currentInput = '';
  bool _confirming = false;
  bool _askingRecoveryWord = false;
  String? _error;
  final TextEditingController _recoveryController = TextEditingController();

  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_currentInput.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      _currentInput += digit;
    });

    if (_currentInput.length == 4) {
      _processFourDigits(_currentInput);
    }
  }

  void _onBackspacePressed() {
    if (_currentInput.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    });
  }

  Future<void> _processFourDigits(String pin) async {
    if (!_confirming) {
      // Step 1: Save first PIN, switch to confirmation
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _firstPin = pin;
        _confirming = true;
        _currentInput = '';
      });
    } else {
      // Step 2: Verify confirmation
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      if (pin == _firstPin) {
        // Check if device has a screen lock
        final isSecure = await widget.repository.isDeviceSecure();
        if (!mounted) return;
        if (!isSecure) {
          // No phone screen lock -> prompt for recovery word
          setState(() {
            _askingRecoveryWord = true;
          });
        } else {
          // Device has fingerprint/screen lock -> ready!
          widget.onSaved(pin, null);
          Navigator.of(context).pop(true);
        }
      } else {
        HapticFeedback.heavyImpact();
        _shakeController.forward(from: 0);
        setState(() {
          _error = 'PINs did not match. Enter again.';
          _confirming = false;
          _firstPin = '';
          _currentInput = '';
        });
      }
    }
  }

  void _finishWithRecoveryAnswer() {
    final answer = _recoveryController.text.trim();
    widget.onSaved(_firstPin, answer.isNotEmpty ? answer : null);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: math.max(MediaQuery.paddingOf(context).bottom, 20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          if (_askingRecoveryWord) ...[
            // Recovery Word Step (When device has NO lock screen)
            Icon(Symbols.shield_lock_rounded, size: 36, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              'No Phone Screen Lock Detected',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your phone doesn’t have a screen lock (PIN/fingerprint). Set a secret recovery word so you can unlock if you ever forget your Public Mode PIN.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _recoveryController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Secret Recovery Word',
                hintText: 'e.g. Favorite city, pet, or passphrase',
                prefixIcon: const Icon(Symbols.key_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onSubmitted: (_) => _finishWithRecoveryAnswer(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onSaved(_firstPin, null);
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _finishWithRecoveryAnswer,
                    child: const Text('Save & Activate'),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Step 1 & 2: Numeric PIN Entry Pad
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Symbols.lock_rounded, size: 24, color: scheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              _confirming ? 'Confirm Your PIN' : 'Set Exit PIN',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _confirming
                  ? 'Re-enter the 4-digit PIN to confirm.'
                  : 'A 4-digit PIN is required before handing your phone over.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Animated PIN Dots
            _AnimatedShake(
              controller: _shakeController,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _currentInput.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: isFilled ? 18 : 16,
                    height: isFilled ? 18 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error != null
                          ? scheme.error
                          : isFilled
                              ? scheme.primary
                              : Colors.transparent,
                      border: Border.all(
                        color: _error != null
                            ? scheme.error
                            : isFilled
                                ? scheme.primary
                                : scheme.outlineVariant.withValues(alpha: 0.7),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: scheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else
              const SizedBox(height: 18),

            const SizedBox(height: 8),

            // Sleek Numeric Keypad
            _NumericKeypad(
              onDigit: _onDigitPressed,
              onBackspace: _onBackspacePressed,
              leftWidget: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PinVerifySheet extends StatefulWidget {
  const _PinVerifySheet({
    required this.expectedPin,
    this.recoveryAnswer,
    this.endsAt = 0,
    required this.onVerified,
    required this.repository,
  });

  final String expectedPin;
  final String? recoveryAnswer;
  final int endsAt;
  final Future<void> Function() onVerified;
  final PublicModeRepository repository;

  @override
  State<_PinVerifySheet> createState() => _PinVerifySheetState();
}

class _PinVerifySheetState extends State<_PinVerifySheet>
    with SingleTickerProviderStateMixin {
  String _currentInput = '';
  String? _error;
  bool _verifyingDevice = false;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_currentInput.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      _currentInput += digit;
    });

    if (_currentInput.length == 4) {
      _verifyPin(_currentInput);
    }
  }

  void _onBackspacePressed() {
    if (_currentInput.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    });
  }

  Future<void> _verifyPin(String input) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    if (input == widget.expectedPin) {
      HapticFeedback.mediumImpact();
      await widget.onVerified();
      if (mounted) Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() {
        _error = 'Incorrect PIN';
        _currentInput = '';
      });
    }
  }

  Future<void> _handleForgotPin() async {
    setState(() => _verifyingDevice = true);
    try {
      final isSecure = await widget.repository.isDeviceSecure();
      if (isSecure) {
        // Authenticate with Device Lock (Biometrics/PIN/Pattern)
        final verified = await widget.repository.authenticateDeviceOwner();
        if (verified) {
          HapticFeedback.mediumImpact();
          await widget.onVerified();
          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verified via device lock · Public Mode ended'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        } else {
          if (mounted) {
            setState(() => _error = 'Device authentication cancelled');
          }
        }
      } else {
        // Phone has NO lock screen configured!
        if (widget.recoveryAnswer != null && widget.recoveryAnswer!.isNotEmpty) {
          _showRecoveryAnswerPrompt();
        } else {
          _showNoLockNotice();
        }
      }
    } finally {
      if (mounted) setState(() => _verifyingDevice = false);
    }
  }

  void _showRecoveryAnswerPrompt() {
    final controller = TextEditingController();
    var hasError = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Recovery Verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your phone does not have a screen lock. Enter your secret recovery word to unlock:',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Secret Recovery Word',
                    errorText: hasError ? 'Incorrect recovery word' : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final entered = controller.text.trim().toLowerCase();
                  final expected = widget.recoveryAnswer!.trim().toLowerCase();
                  if (entered == expected) {
                    Navigator.of(dialogCtx).pop();
                    await widget.onVerified();
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recovery verified · Public Mode ended'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    setDialogState(() => hasError = true);
                  }
                },
                child: const Text('Verify & Unlock'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNoLockNotice() {
    final remainingSecs = widget.endsAt > 0
        ? ((widget.endsAt - DateTime.now().millisecondsSinceEpoch) ~/ 1000).clamp(0, 999999)
        : 0;
    final timeStr = remainingSecs > 0 ? '${remainingSecs ~/ 60}m ${remainingSecs % 60}s' : 'shortly';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('No Phone Lock or Recovery Set'),
        content: Text(
          'Your phone doesn’t have a screen lock or secret recovery word configured.\n\n'
          'Public Mode will automatically end and restore your phone when the timeout expires (in $timeStr), or enter the 4-digit PIN.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: math.max(MediaQuery.paddingOf(context).bottom, 20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Symbols.lock_open_rounded, size: 24, color: scheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter Exit PIN',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your 4-digit PIN to exit Public Mode and restore your phone.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Animated PIN Dots
          _AnimatedShake(
            controller: _shakeController,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _currentInput.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: isFilled ? 18 : 16,
                  height: isFilled ? 18 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _error != null
                        ? scheme.error
                        : isFilled
                            ? scheme.primary
                            : Colors.transparent,
                    border: Border.all(
                      color: _error != null
                          ? scheme.error
                          : isFilled
                              ? scheme.primary
                              : scheme.outlineVariant.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: scheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            const SizedBox(height: 18),

          const SizedBox(height: 8),

          // Sleek Numeric Keypad
          _NumericKeypad(
            onDigit: _onDigitPressed,
            onBackspace: _onBackspacePressed,
            leftWidget: _verifyingDevice
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : IconButton(
                    tooltip: 'Forgot PIN? Unlock with Device Lock',
                    icon: Icon(
                      Symbols.fingerprint_rounded,
                      size: 26,
                      color: scheme.primary,
                    ),
                    onPressed: _handleForgotPin,
                  ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _handleForgotPin,
            child: Text(
              'Forgot PIN?',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.leftWidget,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final Widget? leftWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Center(child: leftWidget ?? const SizedBox.shrink()),
            ),
            const SizedBox(width: 20),
            _buildDigitKey(context, '0'),
            const SizedBox(width: 20),
            SizedBox(
              width: 72,
              height: 72,
              child: IconButton(
                onPressed: onBackspace,
                icon: const Icon(Symbols.backspace_rounded, size: 26),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDigitKey(context, digits[0]),
        const SizedBox(width: 20),
        _buildDigitKey(context, digits[1]),
        const SizedBox(width: 20),
        _buildDigitKey(context, digits[2]),
      ],
    );
  }

  Widget _buildDigitKey(BuildContext context, String digit) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.65),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onDigit(digit),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Text(
              digit,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedShake extends StatelessWidget {
  const _AnimatedShake({
    required this.controller,
    required this.child,
  });

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final val = math.sin(controller.value * math.pi * 4) * 8;
        return Transform.translate(
          offset: Offset(val, 0),
          child: child,
        );
      },
    );
  }
}
