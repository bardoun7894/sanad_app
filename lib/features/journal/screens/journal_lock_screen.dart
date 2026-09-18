import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../l10n/journal_strings.dart';
import '../providers/journal_lock_provider.dart';

class JournalLockScreen extends ConsumerStatefulWidget {
  final bool setupMode;
  const JournalLockScreen({super.key, this.setupMode = false});

  @override
  ConsumerState<JournalLockScreen> createState() => _JournalLockScreenState();
}

class _JournalLockScreenState extends ConsumerState<JournalLockScreen> {
  static const int _pinLength = 4;
  String _entered = '';
  String? _firstPin; // setup: first entry to confirm
  String? _errorText;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    if (!widget.setupMode) {
      ref.read(journalLockProvider.notifier).canUseBiometrics().then((v) {
        if (mounted) setState(() => _biometricAvailable = v);
      });
    }
  }

  void _press(String digit) {
    if (_entered.length >= _pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered += digit;
      _errorText = null;
    });
    if (_entered.length == _pinLength) _submit();
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    final notifier = ref.read(journalLockProvider.notifier);
    final js = JournalStrings(ref.read(languageProvider).language);

    if (widget.setupMode) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = _entered;
          _entered = '';
        });
        return;
      }
      if (_firstPin == _entered) {
        await notifier.setPin(_entered);
        if (mounted) context.pop();
      } else {
        setState(() {
          _errorText = js.pinMismatch;
          _entered = '';
          _firstPin = null;
        });
      }
      return;
    }

    final ok = await notifier.verifyPin(_entered);
    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorText = js.wrongPin;
        _entered = '';
      });
    }
    // On success, JournalGate re-renders and shows the home screen.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final js = JournalStrings(ref.watch(languageProvider).language);
    final bg = isDark ? AppColors.journalBgDark : AppColors.journalBgLight;
    final ink = isDark ? AppColors.journalInkDark : AppColors.journalInkLight;

    final subtitle = widget.setupMode
        ? (_firstPin == null ? js.setPin : js.confirmPin)
        : js.enterPin;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: widget.setupMode,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.lock_outline, size: 48, color: AppColors.journalAccent),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              js.lockTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _errorText ?? subtitle,
              style: TextStyle(
                color: _errorText != null
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing2xl),
            _Dots(count: _pinLength, filled: _entered.length),
            const SizedBox(height: AppTheme.spacing2xl),
            _Keypad(onDigit: _press, onBackspace: _backspace),
            const SizedBox(height: AppTheme.spacingLg),
            if (_biometricAvailable && !widget.setupMode)
              TextButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: Text(js.useBiometric),
                onPressed: () async {
                  await ref
                      .read(journalLockProvider.notifier)
                      .unlockWithBiometric();
                },
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int filled;
  const _Dots({required this.count, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isFilled = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.journalAccent : Colors.transparent,
            border: Border.all(color: AppColors.journalAccent, width: 2),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const _Keypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    return SizedBox(
      width: 300,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.4,
        children: keys.map((k) {
          if (k.isEmpty) return const SizedBox.shrink();
          if (k == '<') {
            return IconButton(
              icon: const Icon(Icons.backspace_outlined),
              onPressed: onBackspace,
            );
          }
          return _KeyButton(digit: k, onTap: () => onDigit(k));
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  const _KeyButton({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppColors.journalSurfaceDark
                : AppColors.journalSurfaceLight,
          ),
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.journalInkDark
                  : AppColors.journalInkLight,
            ),
          ),
        ),
      ),
    );
  }
}
