import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/message.dart';
import 'chat_providers.dart';

/// Bubble shell: mine = cyan on the right, theirs = surface on the left.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.showReadReceipt,
    required this.isRead,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showReadReceipt;
  final bool isRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = switch (message.kind) {
      MessageKind.text => _TextBody(message: message, isMine: isMine),
      MessageKind.voice => _VoiceBody(message: message, isMine: isMine),
      MessageKind.image => _ImageBody(message: message),
      MessageKind.file => _FileBody(message: message, isMine: isMine),
    };

    final time = TimeOfDay.fromDateTime(message.createdAt.toLocal());
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: message.kind == MessageKind.image
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            body,
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.pending)
                  Icon(Icons.schedule,
                      size: 12,
                      color: isMine
                          ? AppColors.onPrimary.withValues(alpha: 0.7)
                          : AppColors.textSecondary)
                else if (message.failed)
                  const Icon(Icons.error_outline,
                      size: 12, color: AppColors.error),
                if (message.pending || message.failed)
                  const SizedBox(width: 4),
                Text(
                  timeLabel,
                  style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: isMine
                          ? AppColors.onPrimary.withValues(alpha: 0.7)
                          : AppColors.textSecondary),
                ),
                if (isMine && showReadReceipt && !message.pending) ...[
                  const SizedBox(width: 4),
                  Icon(isRead ? Icons.done_all : Icons.done,
                      size: 13,
                      color: isRead
                          ? AppColors.cyanBright
                          : AppColors.onPrimary.withValues(alpha: 0.7)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextBody extends StatelessWidget {
  const _TextBody({required this.message, required this.isMine});
  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Text(
      message.content,
      style: AppTypography.bodyLarge.copyWith(
          color: isMine ? AppColors.onPrimary : AppColors.textPrimary),
    );
  }
}

/// Voice message: play/pause + progress bar + duration.
class _VoiceBody extends ConsumerStatefulWidget {
  const _VoiceBody({required this.message, required this.isMine});
  final ChatMessage message;
  final bool isMine;

  @override
  ConsumerState<_VoiceBody> createState() => _VoiceBodyState();
}

class _VoiceBodyState extends ConsumerState<_VoiceBody> {
  AudioPlayer? _player;
  bool _loading = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.message.pending) return;
    if (_player == null) {
      setState(() => _loading = true);
      try {
        final url = await ref
            .read(chatRepositoryProvider)
            .signedMediaUrl(MessageKind.voice, widget.message.content);
        final player = AudioPlayer();
        await player.setUrl(url);
        setState(() => _player = player);
        await player.play();
      } catch (_) {
        // leave silently; bubble shows duration only
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }
    if (_player!.playing) {
      await _player!.pause();
    } else {
      if (_player!.processingState == ProcessingState.completed) {
        await _player!.seek(Duration.zero);
      }
      await _player!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isMine ? AppColors.onPrimary : AppColors.primaryDark;
    final total = Duration(milliseconds: widget.message.durationMs ?? 0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: _loading
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: fg),
                )
              : StreamBuilder<PlayerState>(
                  stream: _player?.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    final done = snapshot.data?.processingState ==
                        ProcessingState.completed;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                          playing && !done ? Icons.pause : Icons.play_arrow,
                          color: fg),
                      onPressed: _toggle,
                    );
                  },
                ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 110,
          child: StreamBuilder<Duration>(
            stream: _player?.positionStream,
            builder: (context, snapshot) {
              final pos = snapshot.data ?? Duration.zero;
              final progress = total.inMilliseconds == 0
                  ? 0.0
                  : (pos.inMilliseconds / total.inMilliseconds)
                      .clamp(0.0, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    color: fg,
                    backgroundColor: fg.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text(Formatters.duration(total),
                      style: AppTypography.caption
                          .copyWith(fontSize: 11, color: fg)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Image attachment with optional blur-until-tap for flagged content.
class _ImageBody extends ConsumerStatefulWidget {
  const _ImageBody({required this.message});
  final ChatMessage message;

  @override
  ConsumerState<_ImageBody> createState() => _ImageBodyState();
}

class _ImageBodyState extends ConsumerState<_ImageBody> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final blurSetting = ref.watch(blurExplicitImagesProvider);
    final shouldBlur =
        widget.message.flagged && blurSetting && !_revealed;

    return FutureBuilder<String>(
      future: ref
          .read(chatRepositoryProvider)
          .signedMediaUrl(MessageKind.image, widget.message.content),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Skeleton(width: 200, height: 200, radius: 14);
        }
        Widget image = ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: snapshot.data!,
            width: 220,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                const Skeleton(width: 220, height: 220, radius: 14),
            errorWidget: (_, _, _) => Container(
                width: 220,
                height: 160,
                color: AppColors.cyan50,
                child: const Icon(Icons.broken_image_outlined)),
          ),
        );
        if (shouldBlur) {
          image = GestureDetector(
            onTap: () => setState(() => _revealed = true),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: image,
              ),
            ),
          );
        }
        return image;
      },
    );
  }
}

class _FileBody extends ConsumerWidget {
  const _FileBody({required this.message, required this.isMine});
  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fg = isMine ? AppColors.onPrimary : AppColors.textPrimary;
    final name = message.content.split('/').last;
    return InkWell(
      onTap: () async {
        try {
          final url = await ref
              .read(chatRepositoryProvider)
              .signedMediaUrl(MessageKind.file, message.content);
          await launchUrl(Uri.parse(url),
              mode: LaunchMode.externalApplication);
        } catch (_) {}
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file, size: 18, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                    color: fg, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}
