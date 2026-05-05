import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pdf/attachments_pdf_service.dart';
import '../services/attachments_details_service.dart';
import '../services/attachments_upload_service.dart';
import '../services/attachments_view_photos_service.dart';
import '../services/attachments_view_service.dart';
import '../styles/attachments_styles.dart';

enum AttachmentsFilter { all, processing, collecting, collected }

class AttachmentsPage extends StatefulWidget {
  const AttachmentsPage({super.key});

  @override
  State<AttachmentsPage> createState() => _AttachmentsPageState();
}

class _AttachmentsPageState extends State<AttachmentsPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? loadError;

  AttachmentsFilter selectedFilter = AttachmentsFilter.all;

  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> attachments = [];

  RealtimeChannel? attachmentsChannel;

  @override
  void initState() {
    super.initState();
    loadAll();
    listenAttachmentsRealtime();
  }

  @override
  void dispose() {
    if (attachmentsChannel != null) {
      supabase.removeChannel(attachmentsChannel!);
    }
    super.dispose();
  }

  String _filterName(AttachmentsFilter filter) {
    return filter.toString().split('.').last;
  }

  void listenAttachmentsRealtime() {
    attachmentsChannel = supabase.channel('public:order_attachments');

    attachmentsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_attachments',
          callback: (_) async => loadAll(),
        )
        .subscribe();
  }

  Future<List<Map<String, dynamic>>> _loadAttachmentsSafeNoOrder() async {
    final data = await supabase
        .from('order_attachments')
        .select(
          'id, order_id, image_url, file_name, description, procuring_entity, storage_path, created_at',
        );

    final list = List<Map<String, dynamic>>.from(data);

    list.sort((a, b) {
      final ad =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bd =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    return list;
  }

  Future<void> loadAll() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
          loadError = null;
        });
      }

      final ordersData = await supabase
          .from('purchase_orders')
          .select(
            'id, po_no, description, item_description, collecting_status, status_datetime, total_amount, created_at',
          )
          .order('created_at', ascending: false);

      final attachmentData = await _loadAttachmentsSafeNoOrder();

      if (!mounted) return;

      setState(() {
        orders = List<Map<String, dynamic>>.from(ordersData);
        attachments = attachmentData;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        loadError = e.toString();
      });

      _showSnack('Load failed: $e');
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    if (selectedFilter == AttachmentsFilter.all) return orders;

    final statusName = _filterName(selectedFilter);

    return orders.where((o) {
      final status = (o['collecting_status'] ?? 'processing')
          .toString()
          .trim()
          .toLowerCase();

      return status == statusName;
    }).toList();
  }

  int _countStatus(String status) {
    return orders.where((o) {
      return (o['collecting_status'] ?? 'processing')
              .toString()
              .trim()
              .toLowerCase() ==
          status;
    }).length;
  }

  List<Map<String, dynamic>> _photosFor(dynamic orderId) {
    return attachments
        .where((a) => a['order_id']?.toString() == orderId?.toString())
        .toList();
  }

  String _text(dynamic v) => v?.toString() ?? '-';

  String _formatDate(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '');
    if (d == null) return '-';

    final local = d.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
        ? 12
        : local.hour;

    final min = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$min $ampm';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AttachmentsStyles.bgDark),
    );
  }

  String _statusOf(Map<String, dynamic> order) {
    final status = (order['collecting_status'] ?? '').toString().trim();
    return status.isEmpty ? 'processing' : status.toLowerCase();
  }

  Color _collectingColor(String? status) {
    switch ((status ?? 'processing').toLowerCase()) {
      case 'collecting':
        return AttachmentsStyles.danger;
      case 'collected':
        return Colors.grey;
      case 'processing':
        return AttachmentsStyles.gold;
      default:
        return AttachmentsStyles.gold;
    }
  }

  String _collectingLabel(String? status) {
    switch ((status ?? 'processing').toLowerCase()) {
      case 'collecting':
        return 'Collecting';
      case 'collected':
        return 'Collected';
      case 'processing':
        return 'Processing';
      default:
        return 'Processing';
    }
  }

  BoxDecoration _orderCardDecoration(Map<String, dynamic> order) {
    final status = _statusOf(order);
    final color = _collectingColor(status);

    return BoxDecoration(
      color: status == 'collected'
          ? AttachmentsStyles.card.withOpacity(0.45)
          : AttachmentsStyles.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.75), width: 1.45),
    );
  }

  Widget _statusSmallPill(Map<String, dynamic> order, {bool mobile = false}) {
    final status = _statusOf(order);
    final color = _collectingColor(status);
    final statusDate = order['status_datetime'];

    final hasDate =
        statusDate != null && statusDate.toString().trim().isNotEmpty;

    return Container(
      constraints: BoxConstraints(maxWidth: mobile ? 185 : 260),
      padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 10, vertical: 6),
      decoration: AttachmentsStyles.statusBox(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _collectingLabel(status).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: mobile ? 10 : 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (hasDate) ...[
            SizedBox(width: mobile ? 4 : 6),
            Icon(
              Icons.access_time_rounded,
              color: color,
              size: mobile ? 10 : 11,
            ),
            SizedBox(width: mobile ? 3 : 4),
            Flexible(
              child: Text(
                _formatDate(statusDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color.withOpacity(0.95),
                  fontSize: mobile ? 8.5 : 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoStatusPill(bool delivered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: delivered
          ? AttachmentsStyles.statusDone
          : AttachmentsStyles.statusPending,
      child: Text(
        delivered ? 'Delivered' : 'Pending',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: delivered ? AttachmentsStyles.green : AttachmentsStyles.gold,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _orderTitleDetails(Map<String, dynamic> order, {bool mobile = false}) {
    final photos = _photosFor(order['id']);

    String procuringEntity = '';
    for (final p in photos) {
      final v = (p['procuring_entity'] ?? '').toString().trim();
      if (v.isNotEmpty) {
        procuringEntity = v;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text(order['description']),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: mobile
              ? AttachmentsStyles.cell.copyWith(fontSize: 16)
              : AttachmentsStyles.cell,
        ),
        if (procuringEntity.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            procuringEntity,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AttachmentsStyles.small,
          ),
        ],
        const SizedBox(height: 5),
        _statusSmallPill(order),
      ],
    );
  }

  String? _storagePathFromUrl(String url) {
    if (url.contains('/object/public/attachments/')) {
      return Uri.decodeFull(
        url.split('/object/public/attachments/').last.split('?').first,
      );
    }

    if (url.contains('/object/sign/attachments/')) {
      return Uri.decodeFull(
        url.split('/object/sign/attachments/').last.split('?').first,
      );
    }

    return null;
  }

  Future<void> _deleteStorageFile(Map<String, dynamic> photo) async {
    final imageUrl = _text(photo['image_url']);
    final orderId = photo['order_id']?.toString();
    final savedPath = photo['storage_path']?.toString().trim();

    final paths = <String>{};

    if (savedPath != null && savedPath.isNotEmpty) paths.add(savedPath);

    final pathFromUrl = _storagePathFromUrl(imageUrl);
    if (pathFromUrl != null && pathFromUrl.trim().isNotEmpty) {
      paths.add(pathFromUrl);
    }

    if (orderId != null && orderId.isNotEmpty) {
      final fileName = imageUrl.split('/').last.split('?').first;
      if (fileName.isNotEmpty && fileName != '-') {
        paths.add('bucket_photos/$orderId/$fileName');
        paths.add('$orderId/$fileName');
      }
    }

    if (paths.isNotEmpty) {
      final removed = await supabase.storage
          .from('attachments')
          .remove(paths.toList());

      if (removed.isEmpty) {
        throw Exception('Storage delete failed. Check bucket delete policy.');
      }
    }
  }

  Future<void> deletePhoto(Map<String, dynamic> photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AttachmentsStyles.bg,
        title: const Text(
          'Delete Photo?',
          style: TextStyle(
            color: AttachmentsStyles.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'This will remove the photo from Supabase storage and the list.',
          style: TextStyle(color: AttachmentsStyles.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AttachmentsStyles.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final id = photo['id'];

      await _deleteStorageFile(photo);
      await supabase.from('order_attachments').delete().eq('id', id);

      if (!mounted) return;

      setState(() {
        attachments.removeWhere((a) => a['id']?.toString() == id?.toString());
      });

      _showSnack('Photo deleted successfully');
    } catch (e) {
      _showSnack('Delete failed: $e');
    }
  }

  Future<void> uploadOrderPhotos(Map<String, dynamic> order) async {
    await AttachmentsUploadService.upload(
      context: context,
      order: order,
      oldPhotos: _photosFor(order['id']),
      onSnack: _showSnack,
      onDone: loadAll,
    );

    if (mounted) setState(() {});
  }

  void openPhotosViewer(Map<String, dynamic> order) {
    AttachmentsViewPhotosService.open(
      context: context,
      order: order,
      photos: _photosFor(order['id']),
      onDelete: (photo) async {
        await deletePhoto(photo);
        await loadAll();
      },
    );
  }

  void openOrderDetails(Map<String, dynamic> order) {
    AttachmentsDetailsService.openDetails(
      context: context,
      order: order,
      photos: _photosFor(order['id']),
      onDone: loadAll,
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool expand = false,
    bool iconOnly = false,
    double? height,
    double? iconSize,
    double? fontSize,
    EdgeInsets? padding,
  }) {
    final child = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: iconOnly ? 38 : (expand ? double.infinity : null),
        height: iconOnly ? (height ?? 34) : height,
        padding:
            padding ??
            EdgeInsets.symmetric(horizontal: iconOnly ? 0 : 8, vertical: 7),
        decoration: AttachmentsStyles.outlineBtn,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AttachmentsStyles.gold, size: iconSize ?? 15),
            if (label.isNotEmpty && !iconOnly) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AttachmentsStyles.goldText.copyWith(
                    fontSize: fontSize ?? 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return expand ? Expanded(child: child) : child;
  }

  Widget _topStatsAndFilters(bool compact) {
    final processing = _countStatus('processing');
    final collecting = _countStatus('collecting');
    final collected = _countStatus('collected');

    final currentLabel = selectedFilter == AttachmentsFilter.all
        ? 'All'
        : _collectingLabel(_filterName(selectedFilter));

    Widget tinyCount({
      required int value,
      required Color color,
      required IconData icon,
    }) {
      return Container(
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: AttachmentsStyles.bgDark.withOpacity(0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          tinyCount(
            value: processing,
            color: AttachmentsStyles.gold,
            icon: Icons.pending_actions_rounded,
          ),
          const SizedBox(width: 7),
          tinyCount(
            value: collecting,
            color: AttachmentsStyles.danger,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(width: 7),
          tinyCount(
            value: collected,
            color: Colors.grey,
            icon: Icons.verified_rounded,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<AttachmentsFilter>(
            color: AttachmentsStyles.bgDark,
            elevation: 18,
            offset: const Offset(0, 38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: AttachmentsStyles.green.withOpacity(0.55),
              ),
            ),
            onSelected: (v) => setState(() => selectedFilter = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: AttachmentsFilter.all, child: Text('All')),
              PopupMenuItem(
                value: AttachmentsFilter.processing,
                child: Text('Processing'),
              ),
              PopupMenuItem(
                value: AttachmentsFilter.collecting,
                child: Text('Collecting'),
              ),
              PopupMenuItem(
                value: AttachmentsFilter.collected,
                child: Text('Collected'),
              ),
            ],
            child: Container(
              height: 31,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: AttachmentsStyles.filterBox(
                active: true,
                color: AttachmentsStyles.green,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AttachmentsStyles.green,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    currentLabel,
                    style: const TextStyle(
                      color: AttachmentsStyles.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AttachmentsStyles.gold,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: AttachmentsStyles.tableHeader,
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Description', style: AttachmentsStyles.header),
          ),
          Expanded(
            flex: 2,
            child: Text('Date', style: AttachmentsStyles.header),
          ),
          Expanded(
            flex: 2,
            child: Text('PDF', style: AttachmentsStyles.header),
          ),
          Expanded(
            flex: 4,
            child: Text('Upload Photos', style: AttachmentsStyles.header),
          ),
          Expanded(
            flex: 3,
            child: Text('Status', style: AttachmentsStyles.header),
          ),
        ],
      ),
    );
  }

  Widget _mobileOrderCard(Map<String, dynamic> order) {
    final photos = _photosFor(order['id']);
    final delivered = photos.isNotEmpty;

    return Opacity(
      opacity: _statusOf(order) == 'collected' ? 0.62 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: _orderCardDecoration(order),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = constraints.maxWidth >= 520 ? 8.0 : 6.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: AttachmentsStyles.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _orderTitleDetails(order, mobile: true)),
                    const SizedBox(width: 8),
                    _photoStatusPill(delivered),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AttachmentsStyles.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _formatDate(order['created_at']),
                        style: AttachmentsStyles.small.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _iconBtn(
                        icon: Icons.picture_as_pdf_outlined,
                        label: '',
                        iconOnly: true,
                        height: 36,
                        iconSize: 15,
                        onTap: () => AttachmentsViewService.viewPdf(
                          context: context,
                          order: order,
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _iconBtn(
                        icon: Icons.download_rounded,
                        label: '',
                        iconOnly: true,
                        height: 36,
                        iconSize: 15,
                        onTap: () => AttachmentsPdfService.downloadPdf(
                          context: context,
                          order: order,
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _iconBtn(
                        icon: Icons.cloud_upload_outlined,
                        label: '',
                        iconOnly: true,
                        height: 36,
                        iconSize: 15,
                        onTap: () => uploadOrderPhotos(order),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _iconBtn(
                        icon: Icons.photo_library_outlined,
                        label: '',
                        iconOnly: true,
                        height: 36,
                        iconSize: 15,
                        onTap: delivered
                            ? () => openPhotosViewer(order)
                            : () {},
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _iconBtn(
                        icon: Icons.edit_note_rounded,
                        label: '',
                        iconOnly: true,
                        height: 36,
                        iconSize: 15,
                        onTap: () => openOrderDetails(order),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _desktopOrderRow(Map<String, dynamic> order) {
    final photos = _photosFor(order['id']);
    final delivered = photos.isNotEmpty;

    return Opacity(
      opacity: _statusOf(order) == 'collected' ? 0.62 : 1,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: _orderCardDecoration(order),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 86),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: _orderTitleDetails(order)),
              Expanded(
                flex: 2,
                child: Text(
                  _formatDate(order['created_at']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AttachmentsStyles.small,
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    _iconBtn(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'View',
                      onTap: () => AttachmentsViewService.viewPdf(
                        context: context,
                        order: order,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _iconBtn(
                      icon: Icons.download_rounded,
                      label: '',
                      onTap: () => AttachmentsPdfService.downloadPdf(
                        context: context,
                        order: order,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _iconBtn(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Upload',
                      onTap: () => uploadOrderPhotos(order),
                    ),
                    const SizedBox(width: 8),
                    if (delivered)
                      _iconBtn(
                        icon: Icons.photo_library_outlined,
                        label: 'View Photos',
                        onTap: () => openPhotosViewer(order),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _photoStatusPill(delivered),
                    const Spacer(),
                    _iconBtn(
                      icon: Icons.edit_note_rounded,
                      label: '',
                      onTap: () => openOrderDetails(order),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;
    final isTablet = width >= 650 && width < 1100;
    final visibleOrders = filteredOrders;

    return Container(
      decoration: AttachmentsStyles.panel,
      padding: EdgeInsets.all(isMobile ? 16 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachments',
            style: AttachmentsStyles.title.copyWith(
              fontSize: isMobile ? 26 : 30,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage order PDFs, uploaded photos, descriptions, and status.',
            style: AttachmentsStyles.subtitle,
          ),
          const SizedBox(height: 16),
          _topStatsAndFilters(isMobile || isTablet),
          const SizedBox(height: 16),
          if (!isMobile && !isTablet) _header(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : loadError != null
                ? Center(
                    child: Text(
                      'Load failed:\n$loadError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AttachmentsStyles.danger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : visibleOrders.isEmpty
                ? const Center(
                    child: Text(
                      'No orders found',
                      style: AttachmentsStyles.subtitle,
                    ),
                  )
                : ListView.builder(
                    itemCount: visibleOrders.length,
                    itemBuilder: (_, index) {
                      return (isMobile || isTablet)
                          ? _mobileOrderCard(visibleOrders[index])
                          : _desktopOrderRow(visibleOrders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
