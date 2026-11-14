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
import 'package:url_launcher/url_launcher.dart';
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

  late final SharedChatArgs _args;
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
    _args = SharedChatArgs(id: widget.conversationId, type: widget.type);
    _initRecorder();
    _loadOrderDetails();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _focusNode.addListener(_onFocusChange);
  }

  Future<void> _loadOrderDetails() async {
    final effectiveOrderId = widget.orderId ?? (widget.type.toLowerCase() == 'order' ? widget.conversationId : null);
    if (effectiveOrderId == null || effectiveOrderId.isEmpty) return;
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
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    setState(() {
      _isRecorderInitialized = true;
    });
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

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;
    _waveformSamples.clear();
    final tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
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
      if (_scrollController.hasClients) {
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
                  orderNumber: (_orderData!['orderNumber'] ?? widget.orderId ?? widget.conversationId.substring(0, 8)).toString(),
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

  void _confirmDelete(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppStrings.of(context).deleteConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(AppStrings.of(context).deleteConfirmBody),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: Text(AppStrings.of(context).cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: Text(
              AppStrings.of(context).delete,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId) {
    ref.read(sharedChatProvider(_args).notifier).deleteMessage(messageId);
  }

  void _editMessage(Message msg) {
    final editController = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).edit),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != msg.content) {
                ref.read(sharedChatProvider(_args).notifier).editMessage(msg.id, newText);
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
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
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _cancelRecording,
                                  icon: const Icon(LucideIcons.x, size: 14, color: AppColors.error),
                                  label: Text(
                                    AppStrings.of(context).cancel,
                                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                    IconButton(
                      icon: const Icon(LucideIcons.camera, color: AppColors.textHint, size: 18),
                      onPressed: _takePhotoDirectly,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      constraints: const BoxConstraints(),
                      tooltip: 'Take Photo',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.paperclip, color: AppColors.textHint, size: 18),
                      onPressed: _showMediaPicker,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      constraints: const BoxConstraints(),
                      tooltip: 'Attach Media',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.mapPin, color: AppColors.textHint, size: 18),
                      onPressed: _sendCurrentLocation,
                      padding: const EdgeInsets.only(right: 12, left: 2),
                      constraints: const BoxConstraints(),
                      tooltip: 'Send Location',
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

class _AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const _AudioPlayerWidget({required this.url, required this.isMe});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  FlutterSoundPlayer? _player;
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;
  StreamSubscription? _playerSubscription;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
    _player!.setSubscriptionDuration(const Duration(milliseconds: 100));
    _playerSubscription = _player!.onProgress!.listen((e) {
      if (mounted) {
        setState(() {
          _position = e.position;
          _duration = e.duration;
        });
      }
    });
    if (mounted) {
      setState(() {
        _isPlayerInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _player?.closePlayer();
    _player = null;
    super.dispose();
  }

  Future<void> _playPause() async {
    if (!_isPlayerInitialized || _player == null) return;
    
    if (_isPlaying) {
      await _player!.pausePlayer();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    } else {
      if (_player!.isPaused) {
        await _player!.resumePlayer();
        if (mounted) {
          setState(() => _isPlaying = true);
        }
      } else {
        if (mounted) {
          setState(() => _isPlaying = true);
        }
        try {
          await _player!.startPlayer(
            fromURI: widget.url,
            whenFinished: () {
              if (mounted) {
                setState(() {
                  _isPlaying = false;
                  _position = Duration.zero;
                });
              }
            },
          );
        } catch (e) {
          debugPrint('Error playing audio: $e');
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String posStr = "${_position.inMinutes.toString().padLeft(2, "0")}:${(_position.inSeconds % 60).toString().padLeft(2, "0")}";
    String durStr = "${_duration.inMinutes.toString().padLeft(2, "0")}:${(_duration.inSeconds % 60).toString().padLeft(2, "0")}";
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _playPause,
          child: Icon(
            _isPlaying ? LucideIcons.pauseCircle : LucideIcons.playCircle,
            color: widget.isMe ? Colors.white : AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              height: 20,
              child: SliderTheme(
                data: SliderThemeData(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: _duration.inMilliseconds > 0 
                      ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0) 
                      : 0.0,
                  activeColor: widget.isMe ? Colors.white : AppColors.primary,
                  inactiveColor: widget.isMe ? Colors.white.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2),
                  onChanged: (val) async {
                    if (_duration != Duration.zero && _player != null) {
                      final position = val * _duration.inMilliseconds;
                      await _player!.seekToPlayer(Duration(milliseconds: position.round()));
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                _duration == Duration.zero ? AppStrings.of(context).voiceMessage : "$posStr / $durStr",
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isMe ? Colors.white.withValues(alpha: 0.8) : AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
