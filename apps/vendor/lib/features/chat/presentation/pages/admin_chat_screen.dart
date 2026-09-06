import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendor/features/chat/presentation/widgets/add_product_in_chat_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:api/api.dart';
import 'dart:ui' as ui;

class AdminChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String title;
  final String? avatar;
  final String? phoneNumber;
  final String? vendorName;
  final String? vendorId;
  final String? type;

  const AdminChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.avatar,
    this.phoneNumber,
    this.vendorName,
    this.vendorId,
    this.type,
  });

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _currentUserRole;
  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordingPath;
  StreamSubscription? _recordingSubscription;
  Duration _recordingDuration = Duration.zero;

  Map<String, dynamic>? _activeTicket;
  Map<String, dynamic>? _orderDetails;
  bool _isLoadingOrder = false;
  bool _isOrderExpanded = false;

  bool _hasMore = true;
  String? _nextCursor;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _setupSocket();
    _loadMessages();
    _initRecorder();
    _loadTicketAndOrderDetails();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initRecorder() async {
    final status = await ph.Permission.microphone.request();
    if (status != ph.PermissionStatus.granted) {
      return;
    }
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  Future<void> _loadUserInfo() async {
    final repository = ref.read(sharedAuthRepositoryProvider);
    final userId = await repository.getUserId();
    final role = await repository.getUserRole();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _currentUserRole = role;
      });
    }
  }

  StreamSubscription<dynamic>? _messageSubscription;

  void _setupSocket() async {
    await ref.read(socketServiceProvider).init();
    _messageSubscription = ref
        .read(socketServiceProvider)
        .onEvent(SocketEvent.chatMessage)
        .listen((data) {
          debugPrint('ðŸ“¥ Admin Socket Message Received: $data');
          if (mounted && data['conversationId'] == widget.conversationId) {
            if (data['senderId']?.toString() != _currentUserId?.toString()) {
              debugPrint('âœ… Adding real-time message to admin list');
              setState(() {
                // Check for duplicates
                if (!_messages.any(
                  (m) => m['id']?.toString() == data['messageId']?.toString(),
                )) {
                  _messages.insert(0, {
                    'id': data['messageId'],
                    'text': data['text'],
                    'type': data['type'] ?? 'TEXT',
                    'mediaUrl': data['mediaUrl'],
                    'sender': {
                      'id': data['senderId'],
                      'role': data['senderRole'] ?? 'CUSTOMER',
                      'name': data['senderName'] ?? 'Customer',
                    },
                    'createdAt': data['createdAt'],
                  });
                  _scrollToBottom();
                }
              });
              if (data['messageId'] != null) {
                ref
                    .read(sharedChatRepositoryProvider)
                    .markAsRead(widget.conversationId, [data['messageId'].toString()]);
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _recordingSubscription?.cancel();
    _recorder?.closeRecorder();
    _recorder = null;
    _messageSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showAddProductDialog() async {
    if (widget.vendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.vendorIdNotFound)),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddProductInChatDialog(
        vendorId: widget.vendorId!,
        vendorName: widget.vendorName ?? "Vendor",
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      
      if (result['imageFile'] != null) {
        final xFile = result['imageFile'] as XFile;
        if (!await _validateMediaSize(xFile.path)) {
          setState(() => _isLoading = false);
          return;
        }
      }
      try {
        String? productId = result['productId'];

        if (productId == null) {
          // ALWAYS create a product to avoid backend 500 error when ordering custom products.
          // If the user didn't want it in the menu, we don't assign it a category.
          final bool addToMenu = result['createProduct'] == true || result['pushToMenu'] == true;
          final dto = CreateProductDto((b) {
            b.name = result['name'];
            b.nameAr = result['nameAr'] ?? result['name'];
            b.basePrice = result['basePrice'] ?? 0.0;
            b.description = result['description'] ?? '';
            b.descriptionAr = result['descriptionAr'] ?? '';
            b.categoryId = addToMenu ? result['categoryId'] : null;
            b.sellByStrip = false;
            b.hasVariants = false;
            b.isActive = true;
            if (result['stock'] != null) b.stock = num.tryParse(result['stock'].toString());
            if (result['sku'] != null && result['sku'].toString().trim().isNotEmpty) {
              b.sku = result['sku'].toString().trim();
            }
          });
          final createdProduct = await ref
              .read(adminVendorsRepositoryProvider)
              .createProduct(widget.vendorId!, dto);
          productId = createdProduct is Map ? createdProduct['id']?.toString() : null;

          if (productId != null && result['imageFile'] != null) {
            final xFile = result['imageFile'] as XFile;
            final multipartFile = await dio.MultipartFile.fromFile(
              xFile.path,
              filename: xFile.name,
            );
            await ref
                .read(adminVendorsRepositoryProvider)
                .uploadProductImage(widget.vendorId!, productId, multipartFile);
          }
        }

        String? offerImageUrl = result['imageUrl']?.toString();
        if (result['imageFile'] != null) {
          final xFile = result['imageFile'] as XFile;
          final uploadRes = await ref
              .read(sharedChatRepositoryProvider)
              .uploadMedia(widget.conversationId, xFile.path);
          offerImageUrl = _extractMediaUrl(uploadRes);
        }

        final metadata = {
          'type': 'OFFER',
          'product': {
            'id': productId,
            'name': result['name'],
            'nameAr': result['nameAr'],
            'description': result['description'],
            'descriptionAr': result['descriptionAr'],
            'price': result['basePrice'],
            'comparePrice': result['comparePrice'],
            'sku': result['sku'],
            'image': offerImageUrl,
          },
          'createPendingOrder': result['createPendingOrder'] == true,
          'vendorId': widget.vendorId,
        };

        final text = "Offer: ${result['name']} - ${result['basePrice']} EGP";

        await ref
            .read(sharedChatRepositoryProvider)
            .sendMessage(widget.conversationId, text, type: 'PRODUCT', metadata: metadata);

        _loadMessages();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorOccurred(e.toString()),
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _escalateTicket() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.escalateComplaint,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(AppLocalizations.of(context)!.escalateComplaintConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isAr ? 'تأكيد التصعيد' : 'Confirm Escalation'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // 1. Fetch active ticket details
      final ticketRepo = ref.read(sharedSupportTicketsRepositoryProvider);
      final result = await ticketRepo.getTickets(limit: 50);
      final tickets = result['tickets'] as List? ?? [];
      final activeTicket = tickets.firstWhere(
        (t) => t['conversationId'] == widget.conversationId,
        orElse: () => null,
      );

      if (activeTicket == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'خطأ: لم يتم العثور على التذكرة النشطة!'
                    : 'Error: Active ticket not found!',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final ticketId = activeTicket['id'].toString();

      // Update status on backend to ESCALATED
      await ticketRepo.ticketsUpdate(
        id: ticketId,
        updateTicketDto: UpdateTicketDto((b) => b..status = UpdateTicketDtoStatusEnum.ESCALATED),
      );

      _loadMessages();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم تصعيد الشكوى للإدارة بنجاح!'
                  : 'Complaint escalated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedWithError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _transferTicket() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // 1. Fetch active ticket to get the ticket ID
    setState(() => _isLoading = true);
    dynamic activeTicket;
    try {
      final ticketRepo = ref.read(sharedSupportTicketsRepositoryProvider);
      final result = await ticketRepo.getTickets(limit: 50);
      final tickets = result['tickets'] as List? ?? [];
      activeTicket = tickets.firstWhere(
        (t) => t['conversationId'] == widget.conversationId,
        orElse: () => null,
      );
    } catch (e) {
      debugPrint('Error fetching ticket: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (activeTicket == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'لم يتم العثور على التذكرة النشطة لهذه المحادثة!'
                  : 'Active ticket not found for this conversation!',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final ticketId = activeTicket['id'].toString();

    // 2. Show Category Selection Dialog
    final selectedCategory = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? 'تحويل الشكوى إلى' : 'Transfer Ticket To',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.truck, color: Colors.blue),
              title: Text(isAr ? 'التوصيل والمناديب' : 'Delivery'),
              onTap: () => Navigator.pop(ctx, 'DELIVERY'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.store, color: AppColors.primary),
              title: Text(isAr ? 'المطاعم والشركاء' : 'Vendors'),
              onTap: () => Navigator.pop(ctx, 'VENDOR'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.creditCard, color: Colors.teal),
              title: Text(isAr ? 'الدفع والحسابات' : 'Payment'),
              onTap: () => Navigator.pop(ctx, 'PAYMENT'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.userCheck, color: Colors.orange),
              title: Text(isAr ? 'إدارة الحساب' : 'Account'),
              onTap: () => Navigator.pop(ctx, 'ACCOUNT'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.rotateCcw, color: Colors.purple),
              title: Text(isAr ? 'المرتجعات والشكاوى' : 'Return / Complaint'),
              onTap: () => Navigator.pop(ctx, 'RETURN_COMPLAINT'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.helpCircle, color: Colors.grey),
              title: Text(isAr ? 'أخرى' : 'Other'),
              onTap: () => Navigator.pop(ctx, 'OTHER'),
            ),
          ],
        ),
      ),
    );

    if (selectedCategory == null) return;

    if (!context.mounted) return;

    // 3. Confirm Transfer Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? 'تأكيد التحويل' : 'Confirm Transfer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من تحويل هذه الشكوى؟ سيتم إلغاء تعيينك وخروجك من المحادثة.'
              : 'Are you sure you want to transfer this ticket? You will be unassigned and kicked from this conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isAr ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;

    // 4. Perform Transfer API Call
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final ticketRepo = ref.read(sharedSupportTicketsRepositoryProvider);

      // Perform PATCH update on backend
      final success = await ticketRepo.ticketsUpdate(
        id: ticketId,
        updateTicketDto: UpdateTicketDto((b) {
          switch (selectedCategory) {
            case 'DELIVERY': b.category = UpdateTicketDtoCategoryEnum.DELIVERY; break;
            case 'VENDOR': b.category = UpdateTicketDtoCategoryEnum.VENDOR; break;
            case 'PAYMENT': b.category = UpdateTicketDtoCategoryEnum.PAYMENT; break;
            case 'ACCOUNT': b.category = UpdateTicketDtoCategoryEnum.ACCOUNT; break;
            case 'RETURN_COMPLAINT': b.category = UpdateTicketDtoCategoryEnum.RETURN_COMPLAINT; break;
            case 'OTHER': b.category = UpdateTicketDtoCategoryEnum.OTHER; break;
          }
        }),
      );

      if (success != null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'تم تحويل الشكوى بنجاح!'
                    : 'Ticket transferred successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Kick and go back to ticket list!
        }
      } else {
        throw Exception("Failed to update ticket category");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedWithError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeTicketStatus() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // 1. Fetch active ticket to get the ticket ID and current status
    setState(() => _isLoading = true);
    dynamic activeTicket;
    try {
      final ticketRepo = ref.read(sharedSupportTicketsRepositoryProvider);
      final result = await ticketRepo.getTickets(limit: 50);
      final tickets = result['tickets'] as List? ?? [];
      activeTicket = tickets.firstWhere(
        (t) => t['conversationId'] == widget.conversationId,
        orElse: () => null,
      );
    } catch (e) {
      debugPrint('Error fetching ticket: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (activeTicket == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'لم يتم العثور على التذكرة النشطة لهذه المحادثة!'
                  : 'Active ticket not found for this conversation!',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final ticketId = activeTicket['id'].toString();
    final currentStatus = activeTicket['status']?.toString() ?? 'OPEN';

    // 2. Show Status Selection Dialog
    final selectedStatus = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? 'تغيير حالة الشكوى' : 'Change Ticket Status',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusTile(
              ctx,
              'OPEN',
              isAr ? 'مفتوح' : 'Open',
              currentStatus,
              Colors.blue,
            ),
            _buildStatusTile(
              ctx,
              'IN_PROGRESS',
              isAr ? 'قيد المعالجة' : 'In Progress',
              currentStatus,
              Colors.orange,
            ),
            _buildStatusTile(
              ctx,
              'WAITING_ON_USER',
              isAr ? 'بانتظار العميل' : 'Waiting on User',
              currentStatus,
              Colors.purple,
            ),
            _buildStatusTile(
              ctx,
              'ESCALATED',
              isAr ? 'تم التصعيد' : 'Escalated',
              currentStatus,
              Colors.amber,
            ),
            _buildStatusTile(
              ctx,
              'RESOLVED',
              isAr ? 'تم الحل' : 'Resolved',
              currentStatus,
              Colors.green,
            ),
            _buildStatusTile(
              ctx,
              'CLOSED',
              isAr ? 'مغلق' : 'Closed',
              currentStatus,
              Colors.grey,
            ),
          ],
        ),
      ),
    );

    if (selectedStatus == null || selectedStatus == currentStatus) return;

    if (!context.mounted) return;

    // 3. Perform Status Change API Call
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final ticketRepo = ref.read(sharedSupportTicketsRepositoryProvider);
      final success = await ticketRepo.ticketsUpdate(
        id: ticketId,
        updateTicketDto: UpdateTicketDto((b) {
          switch (selectedStatus) {
            case 'OPEN': b.status = UpdateTicketDtoStatusEnum.OPEN; break;
            case 'IN_PROGRESS': b.status = UpdateTicketDtoStatusEnum.IN_PROGRESS; break;
            case 'WAITING_ON_USER': b.status = UpdateTicketDtoStatusEnum.WAITING_ON_USER; break;
            case 'ESCALATED': b.status = UpdateTicketDtoStatusEnum.ESCALATED; break;
            case 'RESOLVED': b.status = UpdateTicketDtoStatusEnum.RESOLVED; break;
            case 'CLOSED': b.status = UpdateTicketDtoStatusEnum.CLOSED; break;
          }
        }),
      );

      if (success != null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'تم تحديث حالة الشكوى بنجاح!'
                    : 'Ticket status updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadMessages();
        }
      } else {
        throw Exception("Failed to update ticket status");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedWithError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatusTile(
    BuildContext ctx,
    String value,
    String label,
    String currentStatus,
    Color color,
  ) {
    final isSelected = currentStatus == value;
    return ListTile(
      leading: Icon(
        isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
        color: isSelected ? color : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? color : null,
        ),
      ),
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  Future<void> _loadTicketAndOrderDetails() async {
    if (widget.type != 'SUPPORT') return;

    setState(() {
      _isLoadingOrder = true;
    });

    try {
      final ticketRepo = ref.read(sharedSupportTicketsRepositoryProvider);
      final result = await ticketRepo.getTickets(limit: 50);
      final tickets = result['tickets'] as List? ?? [];
      final active = tickets.firstWhere(
        (t) => t['conversationId'] == widget.conversationId,
        orElse: () => null,
      );

      if (active != null) {
        setState(() {
          _activeTicket = active;
        });

        final orderId = active['order']?['id'] ?? active['orderId'];
        if (orderId != null) {
          final ordersRepo = ref.read(adminOrdersRepositoryProvider);
          final details = await ordersRepo.getOrderById(orderId.toString());
          if (details != null && mounted) {
            setState(() {
              _orderDetails = details;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading ticket/order details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOrder = false;
        });
      }
    }
  }

  Widget _buildOrderBanner() {
    if (widget.type != 'SUPPORT' || _orderDetails == null) {
      return const SizedBox();
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final orderNum = _orderDetails!['orderNumber'] ?? 'N/A';
    final status = _orderDetails!['status']?.toString() ?? 'PENDING';
    final total = _orderDetails!['grandTotal']?.toString() ?? '0';
    final payment = _orderDetails!['paymentMethod']?.toString() ?? 'CASH';
    final address = _orderDetails!['deliveryAddress']?.toString() ?? '';
    final customer = _orderDetails!['customer']?['user'] ?? {};
    final customerName = customer['name'] ?? '';
    final customerPhone = customer['phone'] ?? '';
    final vendor = _orderDetails!['vendor'] ?? {};
    final vendorName = vendor['storeName'] ?? '';
    final items = _orderDetails!['items'] as List? ?? [];

    Color statusColor;
    String statusText;
    switch (status.toUpperCase()) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = isAr ? 'قيد الانتظار' : 'Pending';
        break;
      case 'ACCEPTED':
        statusColor = Colors.blue;
        statusText = isAr ? 'مقبول' : 'Accepted';
        break;
      case 'PREPARING':
        statusColor = Colors.indigo;
        statusText = isAr ? 'قيد التحضير' : 'Preparing';
        break;
      case 'READY_FOR_PICKUP':
        statusColor = Colors.purple;
        statusText = isAr ? 'جاهز للاستلام' : 'Ready';
        break;
      case 'DRIVER_ASSIGNED':
        statusColor = Colors.teal;
        statusText = isAr ? 'تم تعيين المندوب' : 'Driver Assigned';
        break;
      case 'PICKED_UP':
        statusColor = Colors.cyan;
        statusText = isAr ? 'في الطريق' : 'Picked Up';
        break;
      case 'DELIVERED':
        statusColor = Colors.green;
        statusText = isAr ? 'تم التوصيل' : 'Delivered';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = isAr ? 'ملغي' : 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Toggle Bar
            InkWell(
              onTap: () {
                setState(() {
                  _isOrderExpanded = !_isOrderExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.shoppingBag,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isAr ? 'طلب' : 'Order'} $orderNum',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$total ${isAr ? 'ج.م' : 'EGP'} • $vendorName',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isOrderExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            if (_isOrderExpanded) ...[
              Container(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery Details
                    if (customerName.isNotEmpty ||
                        customerPhone.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.user,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              customerName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (customerPhone.isNotEmpty)
                            InkWell(
                              onTap: () async {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: customerPhone,
                                );
                                await launchUrl(launchUri);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.phone,
                                  size: 14,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (address.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.creditCard,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${isAr ? 'طريقة الدفع:' : 'Payment:'} ${payment.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(
                      isAr ? 'المنتجات المطلوبة:' : 'Items Ordered:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Products List
                    ...items.map((item) {
                      final productName = item['product']?['name'] ?? item['productName'] ?? '';
                      final variantName = item['variantName'] ?? '';
                      final quantity = item['quantity'] ?? 1;
                      final itemPrice = item['unitPrice'] ?? '0';
                      final selectedOpts =
                          item['selectedOptions'] as List? ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$quantity x $productName${variantName.isNotEmpty ? ' ($variantName)' : ''}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$itemPrice ${isAr ? 'ج.م' : 'EGP'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            if (selectedOpts.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...selectedOpts.map(
                                (opt) => Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 12,
                                    top: 2,
                                  ),
                                  child: Text(
                                    '+ ${opt['optionName']} (+${opt['priceAdded']} ${isAr ? 'ج.م' : 'EGP'})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _validateMediaSize(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    final config = ref.read(mediaConfigServiceProvider);
    if (!config.validateFileSize(size, 'CHAT')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.fileExceedsMaxSize(MediaConfigService.chatMediaLimitMB.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final ext = path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.onlyImagesAllowed),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (!await _validateMediaSize(path)) return;
      
      final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _messages.insert(0, {
          'id': tempId,
          'text': '',
          'type': 'IMAGE',
          'mediaUrl': null,
          'isUploading': true,
          'sender': {
            'id': _currentUserId,
            'role': 'VENDOR_MEMBER',
            'name': 'Me',
          },
          'createdAt': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();

      final repository = ref.read(sharedChatRepositoryProvider);
      final uploadRes = await repository.uploadMedia(
        widget.conversationId,
        path,
      );
      final mediaUrl = _extractMediaUrl(uploadRes);

      if (mediaUrl != null) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) {
            _messages[idx]['mediaUrl'] = mediaUrl;
            _messages[idx]['isUploading'] = false;
          }
        });

        await repository.sendMessage(
          widget.conversationId,
          '',
          type: 'IMAGE',
          mediaUrl: mediaUrl,
        );
        _loadMessages();
      } else {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
        });
      }
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final ext = path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.onlyImagesAllowed),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (!await _validateMediaSize(path)) return;
      
      final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _messages.insert(0, {
          'id': tempId,
          'text': '',
          'type': 'IMAGE',
          'mediaUrl': null,
          'isUploading': true,
          'sender': {
            'id': _currentUserId,
            'role': 'VENDOR_MEMBER',
            'name': 'Me',
          },
          'createdAt': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();

      final repository = ref.read(sharedChatRepositoryProvider);
      final uploadRes = await repository.uploadMedia(
        widget.conversationId,
        path,
      );
      final mediaUrl = _extractMediaUrl(uploadRes);

      if (mediaUrl != null) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) {
            _messages[idx]['mediaUrl'] = mediaUrl;
            _messages[idx]['isUploading'] = false;
          }
        });

        await repository.sendMessage(
          widget.conversationId,
          '',
          type: 'IMAGE',
          mediaUrl: mediaUrl,
        );
        _loadMessages();
      } else {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
        });
      }
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;
    final tempDir = await getTemporaryDirectory();
    _recordingPath =
        '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: _recordingPath);
    _recordingSubscription = _recorder!.onProgress!.listen((e) {
      if (mounted) {
        setState(() {
          _recordingDuration = e.duration;
        });
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
          return;
        }
      }
      
      if (!await _validateMediaSize(_recordingPath!)) return;

      final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _messages.insert(0, {
          'id': tempId,
          'text': '',
          'type': 'AUDIO',
          'mediaUrl': null,
          'isUploading': true,
          'sender': {
            'id': _currentUserId,
            'role': 'VENDOR_MEMBER',
            'name': 'Me',
          },
          'createdAt': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();

      final repository = ref.read(sharedChatRepositoryProvider);
      final uploadRes = await repository.uploadMedia(
        widget.conversationId,
        _recordingPath!,
      );
      final mediaUrl = _extractMediaUrl(uploadRes);

      if (mediaUrl != null) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) {
            _messages[idx]['mediaUrl'] = mediaUrl;
            _messages[idx]['isUploading'] = false;
          }
        });

        await repository.sendMessage(
          widget.conversationId,
          '',
          type: 'AUDIO',
          mediaUrl: mediaUrl,
        );
        _loadMessages();
      } else {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
        });
      }
    }
  }

  String? _extractMediaUrl(dynamic responseData) {
    if (responseData is Map) {
      if (responseData['data'] != null && responseData['data'] is Map && responseData['data']['url'] != null) {
        return responseData['data']['url'];
      } else if (responseData['url'] != null) {
        return responseData['url'];
      }
    }
    return null;
  }

  Future<void> _loadMessages() async {
    try {
      final repository = ref.read(sharedChatRepositoryProvider);
      final response = await repository.getMessages(widget.conversationId);
      
      List<dynamic> data = [];
      if (response is Map) {
        if (response.containsKey('hasMore')) _hasMore = response['hasMore'] == true;
        if (response.containsKey('nextCursor')) _nextCursor = response['nextCursor'];
      }
      
      if (response is List) {
        data = response;
      } else if (response is Map && response.containsKey('messages')) {
        data = response['messages'];
      } else if (response is Map && response.containsKey('data')) {
        final resData = response['data'];
        if (resData is Map && resData.containsKey('messages')) {
          data = resData['messages'];
        } else if (resData is List) {
          data = resData;
        }
      }

      if (mounted) {
        setState(() {
          // Remove optimistic/temp messages before merging real ones
          _messages.removeWhere(
            (m) => m['id']?.toString().startsWith('temp-') ?? false,
          );

          final fetchedMessages = data.map((m) {
            return Map<String, dynamic>.from(m as Map);
          }).toList().reversed.toList();

          // Merge with existing messages (avoid duplicates from socket)
          for (var msg in fetchedMessages) {
            if (!_messages.any(
              (m) => m['id']?.toString() == msg['id']?.toString(),
            )) {
              _messages.add(msg);
            }
          }

          // Sort by date newest first
          _messages.sort(
            (a, b) => DateTime.parse(
              b['createdAt'],
            ).compareTo(DateTime.parse(a['createdAt'])),
          );

          _isLoading = false;
        });
        _scrollToBottom();
        final validMessages = _messages.where((m) => 
          m['id'] != null && 
          !m['id'].toString().startsWith('temp-') && 
          !m['id'].toString().startsWith('upload-')
        ).toList();
        if (validMessages.isNotEmpty) {
          repository.markAsRead(widget.conversationId, [validMessages.first['id'].toString()]);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOccurred(e.toString())),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final repository = ref.read(sharedChatRepositoryProvider);
      final response = await repository.getMessages(
        widget.conversationId,
        before: _nextCursor,
      );

      List<dynamic> data = [];
      if (response is Map) {
        if (response.containsKey('hasMore')) _hasMore = response['hasMore'] == true;
        if (response.containsKey('nextCursor')) _nextCursor = response['nextCursor'];
      }
      
      if (response is List) {
        data = response;
      } else if (response is Map && response.containsKey('messages')) {
        data = response['messages'];
      } else if (response is Map && response.containsKey('data')) {
        final resData = response['data'];
        if (resData is Map && resData.containsKey('messages')) {
          data = resData['messages'];
        } else if (resData is List) {
          data = resData;
        }
      }

      if (mounted && data.isNotEmpty) {
        setState(() {
          final fetchedMessages = data.map((m) {
            return Map<String, dynamic>.from(m as Map);
          }).toList().reversed.toList();

          for (var msg in fetchedMessages) {
            if (!_messages.any((m) => m['id']?.toString() == msg['id']?.toString())) {
              _messages.add(msg);
            }
          }
          
          _messages.sort(
            (a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])),
          );
        });
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    final repository = ref.read(sharedChatRepositoryProvider);

    // Optimistic update
    setState(() {
      _messages.insert(0, {
        'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
        'text': text,
        'type': 'TEXT',
        'sender': {'id': _currentUserId, 'role': 'VENDOR_MEMBER', 'name': 'Me'},
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    final success = await repository.sendMessage(widget.conversationId, text);
    if (success != null) {
      _loadMessages();
    }
  }

  
  Widget _buildQuickSwitcherDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text('Quick Switch', style: TextStyle(fontWeight: FontWeight.bold)),
              leading: const Icon(LucideIcons.arrowRightLeft),
            ),
            const Divider(),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(sharedInboxProvider);
                  if (state.isLoading && state.conversations.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final others = state.conversations.where((c) => 
                    c['id'].toString() != widget.conversationId && c['type'] != 'SUPPORT'
                  ).toList();
                  
                  if (others.isEmpty) {
                    return Center(child: Text(AppLocalizations.of(context)?.noDataAvailable ?? 'No other active chats'));
                  }
                  
                  return ListView.builder(
                    itemCount: others.length,
                    itemBuilder: (context, index) {
                      final c = others[index];
                      final List<dynamic> participants = c['participants'] ?? [];
                      Map<String, dynamic>? target = c['user'];
                      if (target == null || target.isEmpty) {
                        if (c['type'] == 'SUPPORT') {
                          final p = participants.where((p) => p['role'] != 'ADMIN' && p['role'] != 'SUPPORT').firstOrNull;
                          if (p != null) target = p as Map<String, dynamic>;
                        } else if (participants.isNotEmpty) {
                          final p = participants.where((p) => p['userId'] != _currentUserId).firstOrNull ?? participants.first;
                          target = p as Map<String, dynamic>;
                        }
                      }
                      
                      final title = target?['name'] ?? c['phoneNumber'] ?? 'User';
                      final avatar = target?['avatar'];
                      final phoneNumber = target?['phone'] ?? target?['phoneNumber'] ?? c['phoneNumber'];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundImage: avatar != null && avatar.toString().isNotEmpty 
                              ? NetworkImage(ImageUtils.formatImageUrl(avatar.toString())) 
                              : null,
                          child: (avatar == null || avatar.toString().isEmpty) ? const Icon(Icons.person, size: 16) : null,
                        ),
                        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(c['lastMessage']?['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.pop(context); // close drawer
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminChatScreen(
                                conversationId: c['id'].toString(),
                                title: title,
                                avatar: avatar?.toString(),
                                phoneNumber: phoneNumber?.toString(),
                                type: c['type']?.toString(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: _buildQuickSwitcherDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage:
                  widget.avatar != null && widget.avatar!.isNotEmpty
                  ? NetworkImage(ImageUtils.formatImageUrl(widget.avatar!))
                  : null,
              child: (widget.avatar == null || widget.avatar!.isEmpty)
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.vendorName != null)
                    Text(
                      widget.vendorName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.phone, size: 20),
              onPressed: () async {
                final Uri launchUri = Uri(
                  scheme: 'tel',
                  path: widget.phoneNumber,
                );
                await launchUrl(launchUri);
              },
            ),
          if (widget.type == 'SUPPORT') ...[
            IconButton(
              icon: const Icon(LucideIcons.clipboardCheck, size: 20),
              tooltip: Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تغيير حالة الشكوى'
                  : 'Change Status',
              onPressed: _changeTicketStatus,
            ),
            IconButton(
              icon: const Icon(LucideIcons.arrowRightLeft, size: 20),
              tooltip: Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تحويل الشكوى'
                  : 'Transfer Ticket',
              onPressed: _transferTicket,
            ),
            IconButton(
              icon: const Icon(
                LucideIcons.chevronsUp,
                size: 20,
                color: Colors.amber,
              ),
              tooltip: Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تصعيد عاجل'
                  : 'Escalate',
              onPressed: _escalateTicket,
            ),
          ],
          if (widget.type != 'SUPPORT')
            IconButton(
              icon: const Icon(LucideIcons.plus, size: 20),
              onPressed: _showAddProductDialog,
            ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(LucideIcons.list, size: 20),
              tooltip: Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تبديل سريع'
                  : 'Quick Switch',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          image: DecorationImage(
            image: const NetworkImage(
              'https://www.transparenttextures.com/patterns/cubes.png',
            ),
            opacity: 0.03,
            repeat: ImageRepeat.repeat,
            colorFilter: ColorFilter.mode(
              AppColors.primary.withValues(alpha: 0.1),
              BlendMode.srcATop,
            ),
          ),
        ),
        child: Column(
          children: [
            _buildOrderBanner(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                          _loadMoreMessages();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Start from bottom
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: _messages.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final message = _messages[index];
                          // Use toString() to ensure comparison works even if types differ
                          final isMe =
                              message['sender']['id']?.toString() ==
                              _currentUserId?.toString();
  
                          return GestureDetector(
                            onLongPress: () => _showOptions(message),
                            child: _buildMessageBubble(message, isMe),
                          );
                        },
                      ),
                    ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  void _showOptions(dynamic message) {
    if (message['type'] != 'TEXT' &&
        message['type'] != 'IMAGE' &&
        message['type'] != 'AUDIO' &&
        message['type'] != 'FILE') {
      return;
    }

    final isMe =
        message['sender']['id']?.toString() == _currentUserId?.toString();
    final isAdmin = _currentUserRole == 'SUPER_ADMIN';

    if (!isAdmin && !isMe) return;

    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message['type'] == 'TEXT')
              ListTile(
                leading: const Icon(LucideIcons.edit, color: AppColors.primary),
                title: Text(l10n.editMessage),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.error),
              title: Text(
                l10n.deleteMessage,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(message['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String messageId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
        title: Text(
          l10n.deleteMessage,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.deleteMessageConfirm,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    final success = await ref
        .read(sharedChatRepositoryProvider)
        .deleteMessage(widget.conversationId, messageId);
    if (success != null) {
      setState(() {
        _messages.removeWhere((m) => m['id'] == messageId);
      });
    }
  }

  void _editMessage(dynamic message) {
    final l10n = AppLocalizations.of(context)!;
    final editController = TextEditingController(text: message['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
        title: Text(
          l10n.editMessage,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: l10n.enterNewText,
            hintStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : AppColors.textMuted,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != message['text']) {
                final success = await ref
                    .read(sharedChatRepositoryProvider)
                    .updateMessage(
                      widget.conversationId,
                      message['id'],
                      {'text': newText},
                    );
                if (success != null) {
                  setState(() {
                    final index = _messages.indexWhere(
                      (m) => m['id'] == message['id'],
                    );
                    if (index != -1) {
                      _messages[index]['text'] = newText;
                    }
                  });
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(l10n.update),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, bool isMe) {
    final senderName = message['sender']['name'] ?? 'Unknown';
    final senderRole = message['sender']['role'];
    final time = _formatTime(DateTime.parse(message['createdAt']));

    String displaySenderName = senderName;
    if (senderRole != null) {
      final formattedRole = senderRole
          .toString()
          .replaceAll('_', ' ')
          .toLowerCase()
          .split(' ')
          .map(
            (word) => word.isEmpty
                ? ''
                : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' ');
      displaySenderName = '$senderName ($formattedRole)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, bottom: 4),
              child: Text(
                displaySenderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: senderRole.toString().startsWith('VENDOR_')
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: message['sender']['avatar'] != null
                      ? NetworkImage(
                          ImageUtils.formatImageUrl(
                            message['sender']['avatar'],
                          ),
                        )
                      : null,
                  child: message['sender']['avatar'] == null
                      ? Text(
                          (senderName.isNotEmpty ? senderName[0] : '?').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.primaryGradient : null,
                    color: isMe 
                        ? null 
                        : (Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (message['type']?.toString().toUpperCase() == 'IMAGE')
                        if (message['isUploading'] == true ||
                            message['mediaUrl'] == null)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isMe ? Colors.white : AppColors.primary,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.6,
                                  maxHeight: 250,
                                ),
                                child: Image.network(
                                  ImageUtils.formatImageUrl(
                                    message['mediaUrl'],
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      if (message['type']?.toString().toUpperCase() == 'AUDIO')
                        if (message['isUploading'] == true ||
                            message['mediaUrl'] == null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isMe
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.voiceMessage,
                                style: TextStyle(
                                  color: isMe || Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          )
                        else
                          _AudioPlayerWidget(
                            url: ImageUtils.formatImageUrl(message['mediaUrl']),
                            isMe: isMe,
                          ),
                      if (message['type']?.toString().toUpperCase() == 'FILE' &&
                          message['mediaUrl'] != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.file,
                              color: isMe ? Colors.white : AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'File Attachment',
                                style: TextStyle(
                                  color: isMe || Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (message['text'] != null &&
                          message['text'].toString().isNotEmpty)
                        Text(
                          message['text'] ?? '',
                          style: TextStyle(
                            color: isMe || Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 9,
                          color: isMe
                              ? Theme.of(context).colorScheme.onSurface
                              : (Theme.of(context).brightness == Brightness.dark ? Colors.white60 : AppColors.textMuted),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsetsDirectional.only(
        start: 12,
        end: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
                  color: _isRecording
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRecording
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.3),
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
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
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
                                  icon: const Icon(
                                    LucideIcons.x,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                  label: Text(
                                    AppLocalizations.of(context)!.cancel,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
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
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white 
                                      : AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(
                                    context,
                                  )!.typeYourMessage,
                                  hintStyle: const TextStyle(
                                    
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.image,
                        
                        size: 18,
                      ),
                      onPressed: _pickDocument,
                      padding: const EdgeInsetsDirectional.only(end: 12),
                      constraints: const BoxConstraints(),
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
                child: Icon(
                  LucideIcons.send,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.Hm().format(time);
  }
}

class _AudioPlayerWidget extends ConsumerStatefulWidget {
  final String url;
  final bool isMe;

  const _AudioPlayerWidget({required this.url, required this.isMe});

  @override
  ConsumerState<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<_AudioPlayerWidget> {
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
    String posStr =
        "${_position.inMinutes.toString().padLeft(2, "0")}:${(_position.inSeconds % 60).toString().padLeft(2, "0")}";
    String durStr =
        "${_duration.inMinutes.toString().padLeft(2, "0")}:${(_duration.inSeconds % 60).toString().padLeft(2, "0")}";

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
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: _duration.inMilliseconds > 0
                      ? (_position.inMilliseconds / _duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                      : 0.0,
                  activeColor: widget.isMe ? Colors.white : AppColors.primary,
                  inactiveColor: widget.isMe
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.2),
                  onChanged: (val) async {
                    if (_duration != Duration.zero && _player != null) {
                      final position = val * _duration.inMilliseconds;
                      await _player!.seekToPlayer(
                        Duration(milliseconds: position.round()),
                      );
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8.0),
              child: Text(
                _duration == Duration.zero
                    ? AppLocalizations.of(context)!.voiceMessage
                    : "$posStr / $durStr",
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isMe
                      ? Theme.of(context).colorScheme.onSurface
                      : AppColors.textMuted,
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


