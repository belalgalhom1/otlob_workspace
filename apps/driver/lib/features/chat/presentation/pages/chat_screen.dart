import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:data/data.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class OrderChatScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderChatScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends ConsumerState<OrderChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  SharedChatArgs get _args => SharedChatArgs(id: widget.orderId, type: 'order');

  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordingPath;
  StreamSubscription? _recordingSubscription;
  Duration _recordingDuration = Duration.zero;
  final List<double> _waveformSamples = [];
  bool _hasPoppedForClosed = false;

  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  Map<String, dynamic>? _orderData;
  Message? _replyingTo;
  final FocusNode _focusNode = FocusNode();

  void _onFocusChange() {
    if (_focusNode.hasFocus && _scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _setReplyingTo(Message msg) {
    setState(() {
      _replyingTo = msg;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  MessageReply? _buildReplyPayload() {
    if (_replyingTo == null) return null;
    return MessageReply(
      id: _replyingTo!.id,
      type: _replyingTo!.type,
      text: _replyingTo!.content,
      mediaUrl: _replyingTo!.mediaUrl,
      senderName: _replyingTo!.senderName,
    );
  }

  void _scrollToMessage(String messageId) {
    final messages = ref.read(sharedChatProvider(_args)).value;
    if (messages == null) return;
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1 && _scrollController.hasClients) {
      final targetOffset = (index * 72.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadOrderDetails();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (_hasText.value != hasText) _hasText.value = hasText;
    });
    _focusNode.addListener(_onFocusChange);
  }

  Future<void> _loadOrderDetails() async {
    try {
      final repo = ref.read(driverOrdersRepositoryProvider);
      final res = await repo.getOrderById(widget.orderId);
      if (mounted && res is Map<String, dynamic>) {
        setState(() => _orderData = res);
      }
    } catch (e) {
      debugPrint('Failed to load order for chat header: $e');
    }
  }

  Future<void> _callCustomer() async {
    final cust = _orderData?['customer'];
    final phone = (cust is Map ? (cust['phone'] ?? cust['user']?['phone']) : null)?.toString();
    if (phone == null || phone.isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool _hasCustomerPhone() {
    final cust = _orderData?['customer'];
    final phone = (cust is Map ? (cust['phone'] ?? cust['user']?['phone']) : null)?.toString();
    return phone != null && phone.isNotEmpty;
  }

  String _formatStatusLabel(BuildContext context, String? status) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    switch (status?.toUpperCase()) {
      case 'PREPARING':
        return isAr ? 'قيد التحضير' : 'Preparing';
      case 'READY_FOR_PICKUP':
        return isAr ? 'جاهز للاستلام' : 'Ready for Pickup';
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
        return isAr ? 'قيد التوصيل' : 'Out for Delivery';
      case 'DELIVERED':
        return isAr ? 'تم التوصيل' : 'Delivered';
      case 'CANCELLED':
        return isAr ? 'ملغي' : 'Cancelled';
      default:
        return status ?? (isAr ? 'نشط' : 'Active');
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'OUT_FOR_DELIVERY':
      case 'DELIVERED':
        return AppColors.success;
      case 'PREPARING':
      case 'READY_FOR_PICKUP':
        return AppColors.warning;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  List<QuickReplyChipItem> _getDriverQuickReplies(bool isAr) {
    if (isAr) {
      return const [
        QuickReplyChipItem(text: 'وصلت للموقع 📍', icon: LucideIcons.mapPin),
        QuickReplyChipItem(text: 'أنا عند الباب 🚪', icon: LucideIcons.doorOpen),
        QuickReplyChipItem(text: 'في الطريق إليك 🛵', icon: LucideIcons.bike),
        QuickReplyChipItem(text: 'يرجى الرد على الهاتف 📞', icon: LucideIcons.phone),
        QuickReplyChipItem(text: 'تأخير مروري ٥ دقائق ⏱️', icon: LucideIcons.clock),
      ];
    }
    return const [
      QuickReplyChipItem(text: 'I have arrived 📍', icon: LucideIcons.mapPin),
      QuickReplyChipItem(text: 'I\'m at the door 🚪', icon: LucideIcons.doorOpen),
      QuickReplyChipItem(text: 'On my way 🛵', icon: LucideIcons.bike),
      QuickReplyChipItem(text: 'Please check your phone 📞', icon: LucideIcons.phone),
      QuickReplyChipItem(text: 'Traffic delay 5 mins ⏱️', icon: LucideIcons.clock),
    ];
  }

  void _onQuickReplySelected(String text) {
    ref.read(sharedChatProvider(_args).notifier).sendMessage(text);
  }

  Future<void> _sendCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;

      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      final text = isAr ? '📍 موقع الكابتن' : '📍 Driver Location';

      await ref.read(sharedChatProvider(_args).notifier).sendMessage(
        text,
        type: MessageType.location,
        metadata: {
          'lat': pos.latitude,
          'lng': pos.longitude,
        },
      );
    } catch (e) {
      debugPrint('Error sending location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _isRecorderInitialized = true;
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;
    _waveformSamples.clear();
    final tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/driver_recording_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: _recordingPath);
    _recordingSubscription = _recorder!.onProgress!.listen((e) {
      if (mounted) {
        setState(() {
          _recordingDuration = e.duration;
        });
        if (e.decibels != null) {
          final db = e.decibels!;
          // iOS delivers dBFS (-60 to 0), Android delivers positive dB (0 to ~90)
          final double normalized = db < 0
              ? ((db + 60.0) / 60.0).clamp(0.12, 1.0)
              : (db / 90.0).clamp(0.12, 1.0);
          _waveformSamples.add(((normalized * 100).round()) / 100.0);
        }
      }
    });
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    await _recorder!.stopRecorder();
    _recordingSubscription?.cancel();
    _waveformSamples.clear();
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    await _recorder!.stopRecorder();
    _recordingSubscription?.cancel();
    final duration = _recordingDuration;
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });

    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        final size = await file.length();
        if (size < 100 || duration.inMilliseconds < 800) {
          await file.delete();
          _waveformSamples.clear();
          return;
        }
      }

      const targetCount = 35;
      final List<double> finalWaveform = [];
      if (_waveformSamples.isEmpty) {
        for (int i = 0; i < targetCount; i++) {
          finalWaveform.add(0.25 + 0.5 * ((i % 5) / 5.0));
        }
      } else if (_waveformSamples.length <= targetCount) {
        finalWaveform.addAll(_waveformSamples);
        while (finalWaveform.length < targetCount) {
          finalWaveform.add(finalWaveform.last);
        }
      } else {
        final step = _waveformSamples.length / targetCount;
        for (int i = 0; i < targetCount; i++) {
          final index = (i * step).floor().clamp(0, _waveformSamples.length - 1);
          finalWaveform.add(_waveformSamples[index]);
        }
      }

      final metadata = {
        'waveform': finalWaveform,
        'durationSeconds': duration.inSeconds,
        'durationMs': duration.inMilliseconds,
      };

      final replyId = _replyingTo?.id;
      final replyPayload = _buildReplyPayload();
      if (_replyingTo != null) {
        setState(() => _replyingTo = null);
      }

      ref.read(sharedChatProvider(_args).notifier).sendMedia(
        _recordingPath!,
        MessageType.audio,
        metadata: metadata,
        replyToId: replyId,
        replyTo: replyPayload,
      );
      _waveformSamples.clear();
    }
  }

  @override
  void dispose() {
    _recordingSubscription?.cancel();
    _recorder?.closeRecorder();
    _recorder = null;
    _textController.dispose();
    _scrollController.dispose();
    _hasText.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      final replyId = _replyingTo?.id;
      final replyPayload = _buildReplyPayload();
      if (_replyingTo != null) {
        setState(() => _replyingTo = null);
      }

      ref.read(sharedChatProvider(_args).notifier).sendMessage(
        text,
        replyToId: replyId,
        replyTo: replyPayload,
      );
      _textController.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _takePhotoDirectly() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (pickedFile == null || !mounted) return;

    final caption = await ChatMediaCaptionDialog.show(
      context,
      filePath: pickedFile.path,
      isVideo: false,
    );
    if (caption == null || !mounted) return;

    final replyId = _replyingTo?.id;
    final replyPayload = _buildReplyPayload();
    if (_replyingTo != null) {
      setState(() => _replyingTo = null);
    }

    ref.read(sharedChatProvider(_args).notifier).sendMedia(
      pickedFile.path,
      MessageType.image,
      caption: caption,
      replyToId: replyId,
      replyTo: replyPayload,
    );
  }

  Future<void> _showMediaPicker() async {
    final option = await ChatMediaPickerSheet.show(context, allowVideo: true);
    if (option == null || !mounted) return;

    final picker = ImagePicker();
    XFile? pickedFile;
    bool isVideo = false;

    switch (option) {
      case ChatMediaPickerOption.cameraPhoto:
        pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        break;
      case ChatMediaPickerOption.galleryPhoto:
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        break;
      case ChatMediaPickerOption.cameraVideo:
        pickedFile = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 2),
        );
        isVideo = true;
        break;
      case ChatMediaPickerOption.galleryVideo:
        pickedFile = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );
        isVideo = true;
        break;
    }

    if (pickedFile == null || !mounted) return;

    final caption = await ChatMediaCaptionDialog.show(
      context,
      filePath: pickedFile.path,
      isVideo: isVideo,
    );
    if (caption == null || !mounted) return;

    final replyId = _replyingTo?.id;
    final replyPayload = _buildReplyPayload();
    if (_replyingTo != null) {
      setState(() => _replyingTo = null);
    }

    ref.read(sharedChatProvider(_args).notifier).sendMedia(
      pickedFile.path,
      isVideo ? MessageType.video : MessageType.image,
      caption: caption,
      replyToId: replyId,
      replyTo: replyPayload,
    );
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('http')) return url;
    var baseUrl = ref.read(dioProvider).options.baseUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    final path = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Message>>>(sharedChatProvider(_args), (previous, next) {
      if (next.hasError && !_hasPoppedForClosed) {
        final errStr = next.error.toString();
        if (errStr.contains('CHAT_CONVERSATION_CLOSED') ||
            errStr.contains('NOT_A_PARTICIPANT') ||
            errStr.contains('CONVERSATION_NOT_FOUND') ||
            errStr.contains('403') ||
            errStr.contains('404')) {
          _hasPoppedForClosed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.canPop()) {
              context.pop();
            }
          });
        }
      }
    });

    final chatState = ref.watch(sharedChatProvider(_args));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.orderChat),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.invalidate(sharedChatProvider(_args)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_orderData != null)
            OrderContextBar(
              orderNumber: (_orderData!['orderNumber'] ?? widget.orderId.substring(0, 8)).toString(),
              statusLabel: _formatStatusLabel(context, _orderData!['status']?.toString()),
              statusColor: _getStatusColor(_orderData!['status']?.toString()),
              totalAmount: _orderData!['totalAmount'] != null ? '${_orderData!['totalAmount']} EGP' : null,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.push('/order/${widget.orderId}');
                }
              },
              onCall: _hasCustomerPhone() ? _callCustomer : null,
            ),
          Expanded(
            child: chatState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      size: 40,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ErrorUtils.translate(context, error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(sharedChatProvider(_args)),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(child: Text(l10n.noMessagesYet));
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                      ref.read(sharedChatProvider(_args).notifier).loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Newest messages at bottom
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length + (ref.read(sharedChatProvider(_args).notifier).hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final msg = messages[index];
                      return GestureDetector(
                        onLongPress: () => _setReplyingTo(msg),
                        child: ChatBubbleWidget(
                          isMe: msg.isMe,
                          senderName: msg.senderName,
                          senderRole: msg.senderRole,
                          senderTitle: msg.senderTitle,
                          senderTitleAr: msg.senderTitleAr,
                          mediaUrl: msg.mediaUrl,
                          content: msg.content,
                          type: msg.type.name,
                          time: DateFormat.jm().format(msg.timestamp.toLocal()),
                          isRead: msg.isRead,
                          metadata: msg.metadata,
                          uploadingText: 'Uploading...',
                          fileAttachmentText: 'File Attachment',
                          formatImageUrl: _formatImageUrl,
                          replyToSenderName: msg.replyTo?.senderName,
                          replyToContent: msg.replyTo?.text,
                          replyToType: msg.replyTo?.type.name,
                          replyToMediaUrl: msg.replyTo?.mediaUrl,
                          onReplyTap: msg.replyToId != null ? () => _scrollToMessage(msg.replyToId!) : null,
                          onSwipeToReply: () => _setReplyingTo(msg),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (!chatState.hasError && !_isRecording)
            QuickReplyChips(
              chips: _getDriverQuickReplies(Localizations.localeOf(context).languageCode == 'ar'),
              onSelected: _onQuickReplySelected,
            ),
          if (!chatState.hasError && _replyingTo != null)
            ChatReplyBanner(
              senderName: _replyingTo!.senderName,
              content: _replyingTo!.content,
              type: _replyingTo!.type.name,
              mediaUrl: _replyingTo!.mediaUrl,
              formatImageUrl: _formatImageUrl,
              onCancel: _cancelReply,
            ),
          if (!chatState.hasError) _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    if (_isRecording) {
      final minutes = _recordingDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = _recordingDuration.inSeconds.remainder(60).toString().padLeft(2, '0');

      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.error),
              onPressed: _cancelRecording,
              tooltip: 'Cancel',
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$minutes:$seconds',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 22,
              child: IconButton(
                icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                onPressed: _stopRecording,
              ),
            ),
          ],
        ),
      );
    }

    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = viewInsetsBottom > 0 ? 8.0 : (MediaQuery.of(context).padding.bottom + 8.0);

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 16,
        top: 8,
        bottom: bottomPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.camera,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _takePhotoDirectly,
            tooltip: 'Take Photo',
          ),
          IconButton(
            icon: Icon(
              LucideIcons.paperclip,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showMediaPicker,
            tooltip: 'Attach Media',
          ),
          IconButton(
            icon: Icon(
              LucideIcons.mapPin,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _sendCurrentLocation,
            tooltip: 'Send Location',
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.typeMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<bool>(
            valueListenable: _hasText,
            builder: (context, hasText, _) {
              if (hasText) {
                return CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 24,
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.send,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                );
              }
              return CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                radius: 24,
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.mic,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: _startRecording,
                  tooltip: 'Record Voice Note',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
