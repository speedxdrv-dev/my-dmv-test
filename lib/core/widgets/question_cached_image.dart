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

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) {
                  debugPrint('FullScreen Image load error: $url, $error');
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        '图片加载失败',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        // memCacheWidth: 1080, // 移除 memCacheWidth，部分设备/格式（如AVIF）可能不支持解码时缩放
        imageBuilder: (context, imageProvider) => Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image(
                image: imageProvider,
                height: height,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.zoom_in,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        placeholder: (context, url) => SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: _buildPlaceholder(context, url),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Image load error: $url, $error');
          WidgetsBinding.instance.addPostFrameCallback((_) => onError?.call());
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
