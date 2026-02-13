import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 题目图片组件：使用 cached_network_image 加载，带灰色骨架屏占位，本地缓存
class QuestionCachedImage extends StatelessWidget {
  const QuestionCachedImage({
    super.key,
    required this.imageUrl,
    this.height = 165,
    this.borderRadius = 8,
    this.onError,
  });

  final String imageUrl;
  final double height;
  final double borderRadius;
  final VoidCallback? onError;

  /// 灰色骨架屏占位
  static Widget _buildPlaceholder(BuildContext context, String url) {
    return ColoredBox(
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        fit: BoxFit.contain,
        memCacheWidth: 1080,
        placeholder: (context, url) => _buildPlaceholder(context, url),
        errorWidget: (context, url, error) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onError?.call());
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
