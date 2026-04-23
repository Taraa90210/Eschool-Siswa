import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum PushType { info, success, warning, error }

void showPushBanner({
  BuildContext? context,
  required String title,
  required String body,
  required PushType type,
  VoidCallback? onTap,
  Duration duration = const Duration(seconds: 5),
}) {
  final ctx = context ?? Get.context;
  if (ctx == null) return;

  final theme = Theme.of(ctx);
  final cs = theme.colorScheme;
  final base = cs.primary;

  final Map<PushType, double> op = {
    PushType.info: 0.12,
    PushType.success: 0.16,
    PushType.warning: 0.20,
    PushType.error: 0.24,
  };
  final Map<PushType, IconData> ic = {
    PushType.info: Icons.info_outline,
    PushType.success: Icons.check_circle_outline,
    PushType.warning: Icons.warning_amber_rounded,
    PushType.error: Icons.error_outline,
  };

  final double o = op[type]!;
  final IconData icon = ic[type]!;

  final card = Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // badge icon
      Container(
        height: 44,
        width: 44,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: base.withValues(alpha: o),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: base.withValues(alpha: 0.22), width: 1),
        ),
        child: Icon(icon, color: base, size: 20),
      ),
      const SizedBox(width: 12),
      // teks
      Expanded(
        child: InkWell(
          onTap: () => onTap?.call(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (title.isEmpty ? 'Notifikasi' : title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
      // Tombol close
      InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => Get.closeCurrentSnackbar(),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(Icons.close_rounded,
              color: cs.onSurface.withValues(alpha: 0.6), size: 20),
        ),
      ),
    ],
  );

  Get.closeCurrentSnackbar(); // pastikan ga numpuk

  Get.rawSnackbar(
    snackPosition: SnackPosition.TOP,
    snackStyle: SnackStyle.FLOATING,
    borderRadius: 16,
    isDismissible: true,
    duration: duration,
    backgroundColor: Colors.transparent, // biar card keliatan
    messageText: Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: base.withValues(alpha: o * 1.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.06),
            offset: const Offset(2, 2),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: card,
    ),
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    overlayBlur: 0.0,
    forwardAnimationCurve: Curves.easeOutCubic,
    reverseAnimationCurve: Curves.easeInCubic,
    maxWidth: 600,
  );
}
