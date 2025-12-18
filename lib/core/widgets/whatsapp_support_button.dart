import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../l10n/language_provider.dart';
import 'sanad_button.dart';

class WhatsAppSupportButton extends ConsumerWidget {
  const WhatsAppSupportButton({super.key});

  Future<void> _launchWhatsApp() async {
    final url = Uri.parse('https://wa.me/966501234567');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    const whatsappColor = Color(0xFF25D366);

    return Column(
      children: [
        Text(
          s.paymentIssue,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SanadButton(
          text: s.whatsAppSupport,
          icon: Icons.chat_bubble_outline_rounded,
          variant: SanadButtonVariant.outline,
          backgroundColor: whatsappColor.withValues(alpha: 0.05),
          textColor: whatsappColor,
          borderColor: whatsappColor.withValues(alpha: 0.5),
          onPressed: _launchWhatsApp,
          isFullWidth: true,
        ),
      ],
    );
  }
}
