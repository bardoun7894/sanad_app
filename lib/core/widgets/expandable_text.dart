import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final bool isDark;
  final String? expandLabel;
  final String? collapseLabel;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.isDark = false,
    this.expandLabel,
    this.collapseLabel,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        widget.style ??
        AppTypography.bodyMedium.copyWith(
          color: widget.isDark ? Colors.white70 : AppColors.textSecondary,
          height: 1.5,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.text, style: effectiveStyle);
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
        );
        tp.layout(maxWidth: constraints.maxWidth);
        final isOverflown = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isExpanded)
              MarkdownBody(
                data: widget.text,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(p: effectiveStyle),
              )
            else
              Text(
                widget.text,
                style: effectiveStyle,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            if (isOverflown || _isExpanded) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded
                      ? (widget.collapseLabel ?? 'أقل')
                      : (widget.expandLabel ?? 'قراءة المزيد'),
                  style: effectiveStyle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
