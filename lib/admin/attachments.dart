import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pdf/attachments_pdf_service.dart';
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
            'id, po_no, description, item_description, collecting_status, total_amount, created_at',
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

  Widget _statusSmallPill(String status) {
    final color = _collectingColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AttachmentsStyles.statusBox(color),
      child: Text(
        _collectingLabel(status).toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
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
        _statusSmallPill(_statusOf(order)),
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

  Future<String?> _askDescription() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AttachmentsStyles.bg,
        title: const Text(
          'Photo Description',
          style: TextStyle(color: AttachmentsStyles.textPrimary),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AttachmentsStyles.textPrimary),
          decoration: InputDecoration(
            hintText: 'Write description...',
            hintStyle: const TextStyle(color: AttachmentsStyles.textSecondary),
            filled: true,
            fillColor: AttachmentsStyles.bgDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> openDetails(Map<String, dynamic> order) async {
    final photos = _photosFor(order['id']);

    final descController = TextEditingController(
      text: photos.isNotEmpty
          ? (photos.first['procuring_entity'] ?? '').toString()
          : '',
    );

    String status = _statusOf(order);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AttachmentsStyles.bg,
        title: const Text(
          'Write Procuring Entity',
          style: TextStyle(color: AttachmentsStyles.textPrimary),
        ),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: const TextStyle(color: AttachmentsStyles.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Write Procuring Entity...',
                    hintStyle: const TextStyle(
                      color: AttachmentsStyles.textSecondary,
                    ),
                    filled: true,
                    fillColor: AttachmentsStyles.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: AttachmentsStyles.bg,
                  style: const TextStyle(color: AttachmentsStyles.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AttachmentsStyles.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'processing',
                      child: Text('Processing'),
                    ),
                    DropdownMenuItem(
                      value: 'collecting',
                      child: Text('Collecting'),
                    ),
                    DropdownMenuItem(
                      value: 'collected',
                      child: Text('Collected'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => status = v);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await supabase
                  .from('purchase_orders')
                  .update({'collecting_status': status})
                  .eq('id', order['id']);

              if (photos.isNotEmpty) {
                await supabase
                    .from('order_attachments')
                    .update({'procuring_entity': descController.text.trim()})
                    .eq('order_id', order['id']);
              }

              if (!mounted) return;
              Navigator.pop(context);
              await loadAll();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> uploadPhotos(Map<String, dynamic> order) async {
    final desc = await _askDescription();
    if (desc == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    try {
      final oldPhotos = _photosFor(order['id']);

      String currentProcuringEntity = '';
      for (final p in oldPhotos) {
        final v = (p['procuring_entity'] ?? '').toString().trim();
        if (v.isNotEmpty) {
          currentProcuringEntity = v;
          break;
        }
      }

      for (final file in result.files) {
        if (file.bytes == null) continue;

        final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final fileName =
            'bucket_photos/${order['id']}/${DateTime.now().millisecondsSinceEpoch}_$safeName';

        await supabase.storage
            .from('attachments')
            .uploadBinary(fileName, file.bytes!);

        final url = supabase.storage.from('attachments').getPublicUrl(fileName);

        await supabase.from('order_attachments').insert({
          'order_id': order['id'],
          'image_url': url,
          'file_name': file.name,
          'description': desc,
          'procuring_entity': currentProcuringEntity,
          'storage_path': fileName,
        });
      }

      await loadAll();

      if (mounted) setState(() {});
      _showSnack('Photos uploaded successfully');
    } catch (e) {
      _showSnack('Upload failed: $e');
    }
  }

  void openPhotosViewer(Map<String, dynamic> order) {
    AttachmentsViewService.viewPhotos(
      context: context,
      order: order,
      photos: _photosFor(order['id']),
      onDelete: (photo) async {
        await deletePhoto(photo);
        await loadAll();
      },
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
                        onTap: () => AttachmentsPdfService.viewPdf(
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
                        onTap: () =>
                            AttachmentsPdfService.downloadPdf(order: order),
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
                        onTap: () => uploadPhotos(order),
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
                        onTap: () => openDetails(order),
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
                      onTap: () => AttachmentsPdfService.viewPdf(
                        context: context,
                        order: order,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _iconBtn(
                      icon: Icons.download_rounded,
                      label: '',
                      onTap: () =>
                          AttachmentsPdfService.downloadPdf(order: order),
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
                      onTap: () => uploadPhotos(order),
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
                      onTap: () => openDetails(order),
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
    final compact = isMobile || isTablet;
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
          _topStatsAndFilters(compact),
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
