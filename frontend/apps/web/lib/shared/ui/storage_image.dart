import 'package:core_auth/core_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Supabase Storage のパスから画像を表示する共通ウィジェット。
///
/// [storagePath] が null の場合は [placeholder] を表示する。
/// 画像読み込みエラー時も [placeholder] にフォールバックする。
class StorageImage extends ConsumerWidget {
  const StorageImage({
    super.key,
    required this.storagePath,
    required this.bucket,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  /// Supabase Storage 内のパス (e.g. `scenarios/.../thumbnail.png`)
  final String? storagePath;

  /// バケット名 (e.g. `scenario-assets`)
  final String bucket;

  /// 画像の表示方法
  final BoxFit fit;

  /// パスが null または読み込みエラー時に表示するウィジェット
  final Widget? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = storagePath;
    if (path == null) {
      return _fallback(context);
    }

    final supabase = ref.read(supabaseClientProvider);
    final url = supabase.storage.from(bucket).getPublicUrl(path);

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, _, _) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    if (placeholder != null) {
      return placeholder!;
    }
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
