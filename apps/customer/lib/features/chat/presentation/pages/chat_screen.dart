import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';
import 'package:data/data.dart';
import 'package:ui_kit/ui_kit.dart';
import '../widgets/order_offer_bottom_sheet.dart';
import '../../../../core/widgets/floating_cart_overlay.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String type;
  final String title;
  final String? orderId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.type,
    required this.title,
    this.orderId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  SharedChatArgs get _args => SharedChatArgs(
        id: widget.conversationId,
        type: widget.type.toLowerCase(),
      );
  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordingPath;
  StreamSubscription? _recordingSubscription;
  Duration _recordingDuration = Duration.zero;
  final List<double> _waveformSamples = [];
  bool _hasPoppedForClosed = false;

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
    _loadOrderDetails();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId ||
        oldWidget.type != widget.type ||
        oldWidget.orderId != widget.orderId) {
      _hasPoppedForClosed = false;
      _replyingTo = null;
      _orderData = null;
      _loadOrderDetails();
    }
  }

  Future<void> _loadOrderDetails() async {
    String? effectiveOrderId = widget.orderId;
    if ((effectiveOrderId == null || effectiveOrderId.isEmpty) &&
        widget.type.toLowerCase() == 'order') {
      try {
        final convoRes = await ref
            .read(sharedChatRepositoryProvider)
            .getConversation(widget.conversationId);
        final convoData = convoRes is Map && convoRes.containsKey('data')
            ? convoRes['data']
            : convoRes;
        if (convoData is Map) {
          effectiveOrderId =
              (convoData['orderId'] ?? convoData['order']?['id'])?.toString();
        }
      } catch (_) {}
      effectiveOrderId ??= widget.conversationId;
    }
    if (effectiveOrderId == null || effectiveOrderId.isEmpty || !mounted) return;
    try {
      final repo = ref.read(customerOrderRepositoryProvider);
      final res = await repo.getOrderById(effectiveOrderId);
      if (mounted && res is Map<String, dynamic>) {
        setState(() => _orderData = res);
      }
    } catch (e) {
      debugPrint('Failed to load order for chat header: $e');
    }
  }

  String? _resolveDriverPhone() {
    String? extractPhone(dynamic driver) {
      if (driver is! Map) return null;
      final p = (driver['phone'] ?? driver['user']?['phone'])?.toString().trim();
      return (p != null && p.isNotEmpty) ? p : null;
    }

    final topDriverPhone = extractPhone(_orderData?['driver']);
    if (topDriverPhone != null) return topDriverPhone;

    final groups = _orderData?['deliveryGroups'];
    if (groups is List) {
      for (final g in groups) {
        if (g is! Map) continue;
        final phone = extractPhone(g['primaryDriver'] ?? g['driver']);
        if (phone != null) return phone;
      }
    }
    return null;
  }

  Future<void> _callDriver() async {
    final phone = _resolveDriverPhone();
    if (phone == null || phone.isEmpty) return;
    await ExternalActionLauncher.callPhone(phone, context: context);
  }

  bool _hasDriverPhone() {
    final phone = _resolveDriverPhone();
    return phone != null && phone.isNotEmpty;
  }

  String _formatStatusLabel(BuildContext context, String? status) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return isAr ? 'قيد الانتظار' : 'Pending';
      case 'ACCEPTED':
        return isAr ? 'مقبول' : 'Accepted';
      case 'PREPARING':
        return isAr ? 'قيد التحضير' : 'Preparing';
      case 'CHANGES_REQUESTED':
        return isAr ? 'طلب تعديل' : 'Changes Requested';
      case 'LOOKING_FOR_DRIVER':
        return isAr ? 'جاري البحث عن مندوب' : 'Looking for Driver';
      case 'DRIVER_ASSIGNED':
        return isAr ? 'تم تعيين المندوب' : 'Driver Assigned';
      case 'PENDING_PAYMENT':
        return isAr ? 'بانتظار الدفع' : 'Pending Payment';
      case 'READY_FOR_PICKUP':
        return isAr ? 'جاهز للاستلام' : 'Ready for Pickup';
      case 'PARTIALLY_PICKED_UP':
        return isAr ? 'جاري الاستلام من المتاجر' : 'Partially Picked Up';
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
        return isAr ? 'قيد التوصيل' : 'Out for Delivery';
      case 'DELIVERED':
        return isAr ? 'تم التوصيل' : 'Delivered';
      case 'CANCELLED':
        return isAr ? 'ملغي' : 'Cancelled';
      case 'REJECTED':
        return isAr ? 'مرفوض' : 'Rejected';
      default:
        return status ?? (isAr ? 'نشط' : 'Active');
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PICKED_UP':
      case 'PARTIALLY_PICKED_UP':
      case 'OUT_FOR_DELIVERY':
      case 'DELIVERED':
        return AppColors.success;
      case 'PENDING':
      case 'ACCEPTED':
      case 'PREPARING':
      case 'READY_FOR_PICKUP':
      case 'LOOKING_FOR_DRIVER':
      case 'DRIVER_ASSIGNED':
      case 'PENDING_PAYMENT':
      case 'CHANGES_REQUESTED':
        return AppColors.warning;
      case 'CANCELLED':
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  List<QuickReplyChipItem> _getCustomerQuickReplies(bool isAr) {
    if (isAr) {
      return const [
        QuickReplyChipItem(text: 'اترك الطلب عند الباب 🚪', icon: LucideIcons.doorOpen),
        QuickReplyChipItem(text: 'يرجى رن الجرس 🔔', icon: LucideIcons.bell),
        QuickReplyChipItem(text: 'أنا في طريقي للأسفل ⏳', icon: LucideIcons.clock),
        QuickReplyChipItem(text: 'أنا في الانتظار 📍', icon: LucideIcons.mapPin),
        QuickReplyChipItem(text: 'سأتصل بك الآن 📞', icon: LucideIcons.phone),
      ];
    }
    return const [
      QuickReplyChipItem(text: 'Leave at the door 🚪', icon: LucideIcons.doorOpen),
      QuickReplyChipItem(text: 'Please ring the bell 🔔', icon: LucideIcons.bell),
      QuickReplyChipItem(text: 'I\'m coming down ⏳', icon: LucideIcons.clock),
      QuickReplyChipItem(text: 'I\'m waiting here 📍', icon: LucideIcons.mapPin),
      QuickReplyChipItem(text: 'Calling you now 📞', icon: LucideIcons.phone),
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
      final text = isAr ? '📍 مشاركة الموقع' : '📍 Shared Location';

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

  Future<bool> _ensureRecorderInitialized() async {
    if (_isRecorderInitialized && _recorder != null) return true;
    var status = await Permission.microphone.status;
    if (!status.isGranted && !status.isLimited) {
      if (status.isPermanentlyDenied || status.isRestricted) {
        _showMicSettingsPrompt();
        return false;
      }
      status = await Permission.microphone.request();
    }
    if (!status.isGranted && !status.isLimited) {
      if ((status.isPermanentlyDenied || status.isRestricted) && mounted) {
        _showMicSettingsPrompt();
      }
      return false;
    }
    _recorder ??= FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _isRecorderInitialized = true;
      });
    }
    return true;
  }

  void _showMicSettingsPrompt() {
    if (!mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'يرجى السماح بالوصول إلى الميكروفون من الإعدادات'
              : 'Please allow microphone access in Settings',
        ),
        action: SnackBarAction(
          label: isAr ? 'الإعدادات' : 'Settings',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recordingSubscription?.cancel();
    _recorder?.closeRecorder();
    _recorder = null;
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _showMediaPicker() async {
    final option = await ChatMediaPickerSheet.show(
      context,
      allowVideo: true,
      allowLocation: true,
    );
    if (option == null || !mounted) return;

    if (option == ChatMediaPickerOption.location) {
      await _sendCurrentLocation();
      return;
    }

    final picker = ImagePicker();
    XFile? pickedFile;
    bool isVideo = false;

    try {
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
        case ChatMediaPickerOption.location:
          return;
      }
    } catch (e) {
      if (mounted) {
        MediaPermissionHelper.handlePickerError(e, context: context);
      }
      return;
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

  Future<void> _startRecording() async {
    final ready = await _ensureRecorderInitialized();
    if (!ready || !mounted) return;
    _waveformSamples.clear();
    await VoiceAudioHelper.configureForRecording();
    if (!mounted) return;
    final tempDir = await getTemporaryDirectory();
    if (!mounted || _recorder == null) return;
    _recordingPath = VoiceAudioHelper.buildRecordingPath(tempDir.path);
    await _recorder!.startRecorder(
      toFile: _recordingPath,
      codec: VoiceAudioHelper.recordingCodec,
    );
    if (!mounted) {
      await _recorder?.stopRecorder();
      return;
    }
    await _recordingSubscription?.cancel();
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
    await _recorder?.stopRecorder();
    await _recordingSubscription?.cancel();
    _recordingSubscription = null;
    _waveformSamples.clear();
    
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    await _recorder?.stopRecorder();
    await _recordingSubscription?.cancel();
    _recordingSubscription = null;

    final duration = _recordingDuration;

    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
    }

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
      if (!mounted) return;

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
      if (_replyingTo != null && mounted) {
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

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
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
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

    final messagesAsync = ref.watch(sharedChatProvider(_args));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_orderData != null)
                OrderContextBar(
                  orderNumber: (_orderData!['orderNumber'] ?? widget.orderId ?? (widget.conversationId.length > 8 ? widget.conversationId.substring(0, 8) : widget.conversationId)).toString(),
                  statusLabel: _formatStatusLabel(context, _orderData!['status']?.toString()),
                  statusColor: _getStatusColor(_orderData!['status']?.toString()),
                  totalAmount: (_orderData!['grandTotal'] ?? _orderData!['totalAmount']) != null
                      ? '${_orderData!['grandTotal'] ?? _orderData!['totalAmount']} EGP'
                      : null,
                  onTap: () {
                    final targetId = widget.orderId ?? _orderData!['id']?.toString();
                    if (targetId != null && targetId.isNotEmpty) {
                      context.push('/order-tracking/$targetId');
                    }
                  },
                  onCall: _hasDriverPhone() ? _callDriver : null,
                ),
              Expanded(
                child: messagesAsync.when(
                  data: (messages) => NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                        ref.read(sharedChatProvider(_args).notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Start from bottom
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
                          key: ValueKey(msg.id),
                          onLongPress: () => _showOptions(msg),
                          child: _buildMessage(msg),
                        );
                      },
                    ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) {
                    final errStr = err.toString();
                    if (!_hasPoppedForClosed &&
                        (errStr.contains('CHAT_CONVERSATION_CLOSED') ||
                            errStr.contains('NOT_A_PARTICIPANT') ||
                            errStr.contains('CONVERSATION_NOT_FOUND') ||
                            errStr.contains('403') ||
                            errStr.contains('404'))) {
                      _hasPoppedForClosed = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.canPop()) {
                          context.pop();
                        }
                      });
                    }
                    return Center(child: Text(ErrorUtils.translate(context, err)));
                  },
                ),
              ),
              if (!messagesAsync.hasError && !_isRecording && widget.type.toLowerCase() == 'order')
                QuickReplyChips(
                  chips: _getCustomerQuickReplies(Localizations.localeOf(context).languageCode == 'ar'),
                  onSelected: _onQuickReplySelected,
                ),
              if (!messagesAsync.hasError) ...[
                if (_replyingTo != null)
                  ChatReplyBanner(
                    senderName: _replyingTo!.senderName,
                    content: _replyingTo!.content,
                    type: _replyingTo!.type.name,
                    mediaUrl: _replyingTo!.mediaUrl,
                    formatImageUrl: ImageUtils.formatImageUrl,
                    onCancel: _cancelReply,
                  ),
                _buildInput(),
              ],
            ],
          ),
          const FloatingCartOverlay(),
        ],
      ),
    );
  }

  void _showOptions(Message msg) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.reply, color: AppColors.primary),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                _setReplyingTo(msg);
              },
            ),
            if (msg.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: Text(AppStrings.of(context).edit),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(msg);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(AppStrings.of(context).delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(msg.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String messageId) async {
    final s = AppStrings.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: s.deleteConfirmTitle,
      message: s.deleteConfirmBody,
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      _deleteMessage(messageId);
    }
  }

  void _deleteMessage(String messageId) {
    ref.read(sharedChatProvider(_args).notifier).deleteMessage(messageId);
  }

  void _editMessage(Message msg) {
    final s = AppStrings.of(context);
    final editController = TextEditingController(text: msg.content);
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AppDialog(
          maxWidth: 460,
          header: AppDialogHeader(
            icon: LucideIcons.pencil,
            title: s.edit,
            onClose: () => Navigator.pop(dialogContext),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFieldLabel(
                label: s.isArabic ? 'نص الرسالة' : 'Message text',
                isRequired: true,
              ),
              TextField(
                controller: editController,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
                decoration: AppDialogStyles.inputDecoration(
                  dialogContext,
                  hintText: s.isArabic
                      ? 'أدخل نص الرسالة الجديد...'
                      : 'Enter new text...',
                  icon: LucideIcons.messageSquare,
                  isMultiline: true,
                ),
              ),
              if (errorText != null)
                AppDialogErrorBanner(
                  message: errorText!,
                  margin: const EdgeInsets.only(top: 12),
                ),
            ],
          ),
          footer: AppDialogFooter(
            cancelLabel: s.cancel,
            onCancel: () => Navigator.pop(dialogContext),
            confirmLabel: s.saveChanges,
            confirmIcon: LucideIcons.check,
            onConfirm: () {
              final newText = editController.text.trim();
              if (newText.isEmpty) {
                setDialogState(
                  () => errorText = s.isArabic
                      ? 'يرجى إدخال نص الرسالة'
                      : 'Please enter a message',
                );
                return;
              }
              if (newText != msg.content) {
                ref
                    .read(sharedChatProvider(_args).notifier)
                    .editMessage(msg.id, newText);
              }
              Navigator.pop(dialogContext);
            },
          ),
        ),
      ),
    ).whenComplete(
      () => Future<void>.delayed(
        const Duration(milliseconds: 350),
        editController.dispose,
      ),
    );
  }

  Widget _buildMessage(Message msg) {
    return ChatBubbleWidget(
      isMe: msg.isMe,
      senderName: msg.senderName,
      senderRole: msg.senderRole,
      senderTitle: msg.senderTitle,
      senderTitleAr: msg.senderTitleAr,
      senderAvatarUrl: msg.senderAvatar,
      mediaUrl: msg.mediaUrl,
      content: msg.content,
      type: msg.type.name,
      time: DateFormat.jm().format(msg.timestamp.toLocal()),
      isRead: msg.isRead,
      metadata: msg.metadata,
      uploadingText: AppStrings.of(context).uploading,
      fileAttachmentText: 'File Attachment',
      uploadProgress: msg.uploadProgress,
      localFilePath: msg.localFilePath,
      isUploadFailed: msg.isUploadFailed,
      onRetryUpload: () => ref.read(sharedChatProvider(_args).notifier).retryUpload(msg.id),
      onCancelUpload: () => ref.read(sharedChatProvider(_args).notifier).cancelUpload(msg.id),
      formatImageUrl: ImageUtils.formatImageUrl,
      replyToSenderName: msg.replyTo?.senderName,
      replyToContent: msg.replyTo?.text,
      replyToType: msg.replyTo?.type.name,
      replyToMediaUrl: msg.replyTo?.mediaUrl,
      onReplyTap: msg.replyToId != null ? () => _scrollToMessage(msg.replyToId!) : null,
      onSwipeToReply: () => _setReplyingTo(msg),
      buildOfferBubble: (metadata, isDark) {
         // Create a fake message object for _buildOfferBubble to use, or just pass metadata directly
         return _buildOfferBubble(msg, isDark);
      }
    );
  }

  Widget _buildOfferBubble(Message msg, bool isDark) {
    final s = AppStrings.of(context);
    final product = msg.metadata?['product'] as Map<String, dynamic>?;
    if (product == null) return const SizedBox();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OrderOfferBottomSheet(
            product: {
              ...product,
              'offerMessageId': msg.id,
            },
            vendorId: msg.metadata?['vendorId']?.toString() ?? widget.conversationId, 
            vendorName: widget.title, 
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isMe ? Colors.white.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: msg.isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.package, color: msg.isMe ? Colors.white : AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.offerTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: msg.isMe ? Colors.white : AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if ((product['imageUrl'] ?? product['image']) != null && (product['imageUrl'] ?? product['image']).toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: ImageUtils.thumbnailUrl((product['imageUrl'] ?? product['image']) as String?),
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 120,
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                ),
              ),
            Text(
              product['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: msg.isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${product['price']} ${s.egp}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: msg.isMe ? Colors.white70 : AppColors.primary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => OrderOfferBottomSheet(
                      product: {
                        ...product,
                        'offerMessageId': msg.id,
                      },
                      vendorId: msg.metadata?['vendorId']?.toString() ?? widget.conversationId,
                      vendorName: widget.title,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: msg.isMe ? Colors.white : AppColors.primary,
                  foregroundColor: msg.isMe ? AppColors.primary : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(s.orderNow, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = viewInsetsBottom > 0 ? 8.0 : (MediaQuery.of(context).padding.bottom + 8.0);

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottomPadding,
        top: 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_isRecording) {
                  _stopRecording();
                } else {
                  _startRecording();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isRecording ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRecording ? AppColors.error.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _isRecording ? LucideIcons.send : LucideIcons.mic,
                  color: _isRecording ? AppColors.error : AppColors.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF383838) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _isRecording
                        ? Expanded(
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_recordingDuration.inMinutes.toString().padLeft(2, "0")}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, "0")}',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: TextButton.icon(
                                      onPressed: _cancelRecording,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(
                                        LucideIcons.x,
                                        size: 14,
                                        color: AppColors.error,
                                      ),
                                      label: Text(
                                        AppStrings.of(context).cancel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ),
                          )
                        : Expanded(
                            child: Directionality(
                              textDirection: Directionality.of(context),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: AppStrings.of(context).typeAMessage,
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                    if (!_isRecording)
                      IconButton(
                        icon: const Icon(LucideIcons.paperclip, color: AppColors.textHint, size: 18),
                        onPressed: _showMediaPicker,
                        padding: const EdgeInsetsDirectional.only(end: 10, start: 6),
                        constraints: const BoxConstraints(),
                        tooltip: Localizations.localeOf(context).languageCode == 'ar'
                            ? 'مشاركة الوسائط'
                            : 'Share Media',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
