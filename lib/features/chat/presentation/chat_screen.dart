import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_providers.dart';
import '../../settings/presentation/report_sheet.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/message.dart';
import 'chat_providers.dart';
import 'message_bubbles.dart';

/// 1-to-1 chat. Keyboard-safe by construction: resizeToAvoidBottomInset
/// (default true) + reversed ListView + input pinned in a SafeArea column.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _recorder = AudioRecorder();
  RealtimeChannel? _room;
  Timer? _typingOff;
  bool _otherTyping = false;
  bool _otherOnline = false;
  bool _recording = false;
  bool _cancelRecording = false;
  DateTime? _recordStart;
  final List<ChatMessage> _pending = [];

  @override
  void initState() {
    super.initState();
    final repo = ref.read(chatRepositoryProvider);
    repo.markRead(widget.conversationId);
    _room = repo.joinRoom(
      widget.conversationId,
      onTyping: (typing) {
        if (mounted) setState(() => _otherTyping = typing);
      },
      onPresence: (online) {
        if (mounted) setState(() => _otherOnline = online);
      },
    );
  }

  @override
  void dispose() {
    final repo = ref.read(chatRepositoryProvider);
    if (_room != null) repo.leaveRoom(_room!);
    _typingOff?.cancel();
    _input.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _onTextChanged(String _) {
    final repo = ref.read(chatRepositoryProvider);
    if (_room != null) repo.sendTyping(_room!, true);
    _typingOff?.cancel();
    _typingOff = Timer(const Duration(seconds: 2), () {
      if (_room != null) repo.sendTyping(_room!, false);
    });
  }

  ChatMessage _optimistic(MessageKind kind, String content,
      {int? durationMs}) {
    final repo = ref.read(chatRepositoryProvider);
    return ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      conversationId: widget.conversationId,
      senderId: repo.uid,
      kind: kind,
      content: content,
      durationMs: durationMs,
      createdAt: DateTime.now().toUtc(),
      pending: true,
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
    );
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final msg = _optimistic(MessageKind.text, text);
    setState(() => _pending.add(msg));
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendText(widget.conversationId, text);
      setState(() => _pending.removeWhere((m) => m.localId == msg.localId));
    } catch (e) {
      setState(() {
        final i = _pending.indexWhere((m) => m.localId == msg.localId);
        if (i != -1) _pending[i] = msg.copyWith(pending: false, failed: true);
      });
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _retry(ChatMessage failed) async {
    setState(() => _pending.removeWhere((m) => m.localId == failed.localId));
    if (failed.kind == MessageKind.text) {
      _input.text = failed.content;
      await _sendText();
    }
  }

  Future<void> _pickAttachment() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined,
                  color: AppColors.primaryDark),
              title: Text(l10n.attachImage),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file,
                  color: AppColors.primaryDark),
              title: Text(l10n.attachFile),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    try {
      File? file;
      var isImage = choice == 'image';
      if (isImage) {
        final x = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85);
        if (x != null) file = File(x.path);
      } else {
        final result = await FilePicker.platform.pickFiles();
        final path = result?.files.single.path;
        if (path != null) file = File(path);
      }
      if (file == null) return;
      final msg = _optimistic(
          isImage ? MessageKind.image : MessageKind.file, file.path);
      setState(() => _pending.add(msg));
      await ref
          .read(chatRepositoryProvider)
          .sendAttachment(widget.conversationId, file, isImage: isImage);
      setState(() => _pending.removeWhere((m) => m.localId == msg.localId));
    } catch (e) {
      setState(() => _pending.removeWhere((m) => m.pending));
      if (mounted) showAppError(context, e);
    }
  }

  // ---- Voice recording (hold to record, slide left to cancel) ----------

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return;
      final path =
          '${Directory.systemTemp.path}/gismat-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() {
        _recording = true;
        _cancelRecording = false;
        _recordStart = DateTime.now();
      });
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _finishRecording() async {
    if (!_recording) return;
    final start = _recordStart;
    setState(() => _recording = false);
    try {
      final path = await _recorder.stop();
      if (path == null || _cancelRecording || start == null) return;
      final durationMs =
          DateTime.now().difference(start).inMilliseconds;
      if (durationMs < 600) return; // ignore accidental taps
      final msg =
          _optimistic(MessageKind.voice, path, durationMs: durationMs);
      setState(() => _pending.add(msg));
      await ref.read(chatRepositoryProvider).sendVoice(
          widget.conversationId, File(path),
          durationMs: durationMs);
      setState(() => _pending.removeWhere((m) => m.localId == msg.localId));
    } catch (e) {
      setState(() => _pending.removeWhere((m) => m.pending));
      if (mounted) showAppError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages =
        ref.watch(conversationMessagesProvider(widget.conversationId));
    final otherReadAt =
        ref.watch(otherReadAtProvider(widget.conversationId)).valueOrNull;
    final summary = ref
        .watch(conversationSummaryProvider(widget.conversationId))
        .valueOrNull;
    final myId = ref.read(chatRepositoryProvider).uid;

    // Mark incoming messages read while the screen is open.
    ref.listen(conversationMessagesProvider(widget.conversationId),
        (previous, next) {
      final prevLen = previous?.valueOrNull?.length ?? 0;
      final list = next.valueOrNull;
      if (list != null && list.length > prevLen) {
        ref.read(chatRepositoryProvider).markRead(widget.conversationId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: summary == null
            ? const SizedBox.shrink()
            : Row(
                children: [
                  GismatAvatar(
                    url: summary.otherPhotoPath == null
                        ? null
                        : ref
                            .read(profileRepositoryProvider)
                            .publicPhotoUrl(summary.otherPhotoPath!),
                    size: 38,
                    online: _otherOnline || summary.otherOnline,
                    verified: summary.otherVerified,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(summary.otherFirstName,
                            style: AppTypography.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          _otherTyping
                              ? l10n.typing
                              : (_otherOnline || summary.otherOnline)
                                  ? l10n.online
                                  : summary.otherLastSeen == null
                                      ? ''
                                      : l10n.lastSeen(timeago
                                          .format(summary.otherLastSeen!)),
                          style: AppTypography.caption.copyWith(
                              color: _otherTyping
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          if (summary != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'report':
                    await showReportSheet(context, ref,
                        userId: summary.otherUserId,
                        userName: summary.otherFirstName);
                  case 'block':
                    final blocked = await confirmBlock(context, ref,
                        userId: summary.otherUserId,
                        userName: summary.otherFirstName);
                    if (blocked && context.mounted) context.pop();
                  case 'unmatch':
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: Text(l10n
                            .unmatchConfirm(summary.otherFirstName)),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: Text(l10n.cancel)),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: Text(l10n.unmatch,
                                  style: const TextStyle(
                                      color: AppColors.error))),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        await ref
                            .read(safetyRepositoryProvider)
                            .unmatch(summary.matchId);
                        ref.invalidate(conversationsProvider);
                        if (context.mounted) context.pop();
                      } catch (e) {
                        if (context.mounted) showAppError(context, e);
                      }
                    }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'report', child: Text(l10n.report)),
                PopupMenuItem(value: 'block', child: Text(l10n.block)),
                PopupMenuItem(value: 'unmatch', child: Text(l10n.unmatch)),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  icon: Icons.wifi_off,
                  title: l10n.errorLoadFailed,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(
                      conversationMessagesProvider(widget.conversationId)),
                ),
                data: (list) {
                  final all = [..._pending.reversed, ...list];
                  if (all.isEmpty) {
                    return EmptyState(
                        icon: Icons.waving_hand_outlined,
                        title: l10n.sayHi);
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md),
                    itemCount: all.length,
                    itemBuilder: (context, i) {
                      final m = all[i];
                      final isMine = m.senderId == myId;
                      final isRead = otherReadAt != null &&
                          !otherReadAt.isBefore(m.createdAt);
                      final bubble = MessageBubble(
                        message: m,
                        isMine: isMine,
                        showReadReceipt: true,
                        isRead: isRead,
                      );
                      if (m.failed) {
                        return Semantics(
                          button: true,
                          label: l10n.messageFailed,
                          child: GestureDetector(
                              onTap: () => _retry(m), child: bubble),
                        );
                      }
                      return bubble;
                    },
                  );
                },
              ),
            ),
            _InputBar(
              controller: _input,
              recording: _recording,
              cancelArmed: _cancelRecording,
              onChanged: _onTextChanged,
              onSend: _sendText,
              onAttach: _pickAttachment,
              onRecordStart: _startRecording,
              onRecordEnd: _finishRecording,
              onRecordSlide: (cancel) =>
                  setState(() => _cancelRecording = cancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom input bar: emoji-capable text field, attach, mic (hold to talk),
/// send.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.recording,
    required this.cancelArmed,
    required this.onChanged,
    required this.onSend,
    required this.onAttach,
    required this.onRecordStart,
    required this.onRecordEnd,
    required this.onRecordSlide,
  });

  final TextEditingController controller;
  final bool recording;
  final bool cancelArmed;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordEnd;
  final ValueChanged<bool> onRecordSlide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: recording
          ? SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.mic,
                      color:
                          cancelArmed ? AppColors.error : AppColors.poke),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      cancelArmed ? l10n.cancel : l10n.slideToCancel,
                      style: AppTypography.body.copyWith(
                          color: cancelArmed
                              ? AppColors.error
                              : AppColors.textSecondary),
                    ),
                  ),
                  _MicButton(
                    onStart: onRecordStart,
                    onEnd: onRecordEnd,
                    onSlide: onRecordSlide,
                  ),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: l10n.attachFile,
                  onPressed: onAttach,
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primaryDark, size: 28),
                ),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: l10n.typeMessage,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _MicButton(
                  onStart: onRecordStart,
                  onEnd: onRecordEnd,
                  onSlide: onRecordSlide,
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => IconButton(
                    tooltip: l10n.typeMessage,
                    onPressed:
                        value.text.trim().isEmpty ? null : onSend,
                    icon: Icon(Icons.send_rounded,
                        color: value.text.trim().isEmpty
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        size: 28),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton(
      {required this.onStart, required this.onEnd, required this.onSlide});

  final VoidCallback onStart;
  final VoidCallback onEnd;
  final ValueChanged<bool> onSlide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.holdToRecord,
      child: GestureDetector(
        onLongPressStart: (_) => onStart(),
        onLongPressMoveUpdate: (details) =>
            onSlide(details.offsetFromOrigin.dx < -60),
        onLongPressEnd: (_) => onEnd(),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Icon(Icons.mic_none, color: AppColors.poke, size: 28),
        ),
      ),
    );
  }
}
