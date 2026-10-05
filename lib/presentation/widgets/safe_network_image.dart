import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Image.network yang aman untuk Flutter Web.
///
/// Masalah: di Flutter Web (CanvasKit) gambar diunduh lewat XHR/fetch, dan
/// books.google.com TIDAK mengirim header CORS -> gambar gagal dimuat.
/// `WebHtmlElementStrategy.fallback` membuat Flutter jatuh ke elemen <img>
/// bawaan browser (yang tidak terkena CORS) bila unduhan biasa gagal.
/// Di Android/iOS/desktop parameter ini diabaikan.
class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? fallback;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final u = url?.trim() ?? '';
    // Image.network('') melempar exception -> langsung tampilkan fallback
    if (u.isEmpty) return _fallback();

    return Image.network(
      u,
      height: height,
      width: width,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, __, ___) => _fallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          width: width,
          color: AppColors.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _fallback() =>
      fallback ??
      Container(
        height: height,
        width: width,
        color: AppColors.surface,
        child: const Icon(Icons.book, color: AppColors.primary),
      );
}
