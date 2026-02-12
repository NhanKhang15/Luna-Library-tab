import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_styles.dart';

enum InfoBoxType { author, notice }

class InfoBox extends StatelessWidget {
  final InfoBoxType type;
  final String text;

  const InfoBox({super.key, required this.type, required this.text});

  @override
  Widget build(BuildContext context) {
    final isAuthor = type == InfoBoxType.author;
    final backgroundColor = isAuthor
        ? const Color(0xFFF3E5F5) // Purple 50
        : const Color(0xFFE3F2FD); // Blue 50
    final startColor = isAuthor
        ? const Color(0xFF9C27B0) // Purple 500
        : const Color(0xFF2196F3); // Blue 500
    final icon = isAuthor
        ? Icons.edit_note_rounded
        : Icons.lightbulb_outline_rounded;
    final iconColor = isAuthor
        ? Colors.purple
        : Colors.orange; // Based on Figma icons

    // Parsing text for bold parts (e.g. "Tác giả:", "Lưu ý:") is simple string manipulation or RichText
    // For simplicity, we assume the input text handles the full content,
    // but the design shows "Tác giả:" in bold.
    // Let's do a simple split if possible or just use RichText if we want strict matching.
    // Given the prompt examples: "Tác giả: ..." and "Lưu ý: ..."
    // We can try to bold the part before the first colon.

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored left border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: startColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppStyles.radiusMedium),
                  bottomLeft: Radius.circular(AppStyles.radiusMedium),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppStyles.spacingM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: iconColor),
                    const SizedBox(width: AppStyles.spacingS),
                    Expanded(child: _buildRichText()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichText() {
    final firstColonIndex = text.indexOf(':');
    if (firstColonIndex == -1) {
      return Text(text, style: AppStyles.bodySmall);
    }

    final prefix = text.substring(0, firstColonIndex + 1);
    final content = text.substring(firstColonIndex + 1);

    return RichText(
      text: TextSpan(
        style: AppStyles.bodySmall.copyWith(color: AppColors.textPrimary),
        children: [
          TextSpan(
            text: prefix,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: content),
        ],
      ),
    );
  }
}
