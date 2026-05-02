import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  String _money(dynamic value) {
    final n = num.tryParse(value?.toString() ?? '0') ?? 0;
    return '₱${n.toStringAsFixed(2)}';
  }

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

  Future<List<Map<String, dynamic>>> _loadOrderItems(String orderId) async {
    final items = await supabase
        .from('purchase_order_items')
        .select(
          'stock_no, unit, item_description, location, quantity, unit_cost, total_cost',
        )
        .eq('purchase_order_id', orderId)
        .order('stock_no', ascending: true);

    return List<Map<String, dynamic>>.from(items);
  }

  TableRow _tableRow(List<String> values, {bool header = false}) {
    return TableRow(
      decoration: header ? const BoxDecoration(color: Color(0xFFEFEFEF)) : null,
      children: values.map((v) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            v,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: header ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> viewPdf(Map<String, dynamic> order) async {
    final items = await _loadOrderItems(order['id']);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) {
        final isMobile = MediaQuery.of(context).size.width < 650;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 18,
            vertical: isMobile ? 14 : 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
          ),
          child: SizedBox(
            width: isMobile ? double.infinity : 820,
            height: MediaQuery.of(context).size.height * 0.88,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PURCHASE ORDER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description: ${_text(order['description'])}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Date: ${_formatDate(order['created_at'])}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Description: ${_text(order['description'])}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              'Date: ${_formatDate(order['created_at'])}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: isMobile ? 720 : 760,
                          child: Table(
                            border: TableBorder.all(color: Colors.black54),
                            columnWidths: const {
                              0: FlexColumnWidth(0.9),
                              1: FlexColumnWidth(0.8),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(1.3),
                              4: FlexColumnWidth(0.7),
                              5: FlexColumnWidth(1.2),
                              6: FlexColumnWidth(1.2),
                            },
                            children: [
                              _tableRow([
                                'STOCK NO.',
                                'UNIT',
                                'ITEM DESCRIPTION',
                                'LOCATION',
                                'QTY',
                                'UNIT COST',
                                'TOTAL COST',
                              ], header: true),
                              ...items.map(
                                (i) => _tableRow([
                                  _text(i['stock_no']),
                                  _text(i['unit']),
                                  _text(i['item_description']),
                                  _text(i['location']),
                                  _text(i['quantity']),
                                  _money(i['unit_cost']),
                                  _money(i['total_cost']),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black54),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'TOTAL AMOUNT',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          _money(order['total_amount']),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    bool right = false,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      height: 34,
      alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      child: pw.Text(
        text,
        maxLines: 2,
        style: pw.TextStyle(
          font: bold ? boldFont : font,
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> downloadPdf(Map<String, dynamic> order) async {
    final items = await _loadOrderItems(order['id']);

    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 42, vertical: 34),
        build: (_) => pw.Column(
          children: [
            pw.Text(
              'PURCHASE ORDER',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 28),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Description: ${_text(order['description'])}',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Text(
                  'Date: ${_formatDate(order['created_at'])}',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 22),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.9),
                1: pw.FlexColumnWidth(0.8),
                2: pw.FlexColumnWidth(2.0),
                3: pw.FlexColumnWidth(1.3),
                4: pw.FlexColumnWidth(0.7),
                5: pw.FlexColumnWidth(1.2),
                6: pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFEFEFEF),
                  ),
                  children: [
                    _pdfCell(
                      'STOCK NO.',
                      bold: true,
                      font: font,
                      boldFont: boldFont,
                    ),
                    _pdfCell(
                      'UNIT',
                      bold: true,
                      font: font,
                      boldFont: boldFont,
                    ),
                    _pdfCell(
                      'ITEM DESCRIPTION',
                      bold: true,
                      font: font,
                      boldFont: boldFont,
                    ),
                    _pdfCell(
                      'LOCATION',
                      bold: true,
                      font: font,
                      boldFont: boldFont,
                    ),
                    _pdfCell('QTY', bold: true, font: font, boldFont: boldFont),
                    _pdfCell(
                      'UNIT COST',
                      bold: true,
                      font: font,
                      boldFont: boldFont,
                    ),
                    _pdfCell(
                      'TOTAL COST',
                      bold: true,
                      font: font,
                      boldFont: boldFont,
                    ),
                  ],
                ),
                ...items.map(
                  (i) => pw.TableRow(
                    children: [
                      _pdfCell(
                        _text(i['stock_no']),
                        font: font,
                        boldFont: boldFont,
                      ),
                      _pdfCell(
                        _text(i['unit']),
                        font: font,
                        boldFont: boldFont,
                      ),
                      _pdfCell(
                        _text(i['item_description']),
                        font: font,
                        boldFont: boldFont,
                      ),
                      _pdfCell(
                        _text(i['location']),
                        font: font,
                        boldFont: boldFont,
                      ),
                      _pdfCell(
                        _text(i['quantity']),
                        font: font,
                        boldFont: boldFont,
                      ),
                      _pdfCell(
                        _money(i['unit_cost']),
                        right: true,
                        font: font,
                        boldFont: boldFont,
                      ),
                      _pdfCell(
                        _money(i['total_cost']),
                        right: true,
                        font: font,
                        boldFont: boldFont,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'TOTAL AMOUNT',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(
                    _money(order['total_amount']),
                    style: pw.TextStyle(
                      font: boldFont,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${_text(order['description'])}_purchase_order.pdf',
    );
  }

  void viewPhotos(Map<String, dynamic> order) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.78),
      builder: (_) {
        final isMobile = MediaQuery.of(context).size.width < 650;

        return StatefulBuilder(
          builder: (context, refreshModal) {
            final photos = _photosFor(order['id']);

            return Dialog(
              backgroundColor: AttachmentsStyles.bg,
              insetPadding: EdgeInsets.all(isMobile ? 10 : 18),
              child: Container(
                width: isMobile ? double.infinity : 900,
                height: isMobile
                    ? MediaQuery.of(context).size.height * 0.60
                    : MediaQuery.of(context).size.height * 0.86,
                padding: EdgeInsets.all(isMobile ? 14 : 18),
                decoration: AttachmentsStyles.panel,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          color: AttachmentsStyles.gold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Uploaded Photos - ${_text(order['description'])}',
                            style: AttachmentsStyles.title.copyWith(
                              fontSize: isMobile ? 16 : 20,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AttachmentsStyles.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Date: ${_formatDate(order['created_at'])}',
                        style: AttachmentsStyles.small.copyWith(
                          color: AttachmentsStyles.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: photos.isEmpty
                          ? const Center(
                              child: Text(
                                'No uploaded photos yet',
                                style: AttachmentsStyles.subtitle,
                              ),
                            )
                          : GridView.builder(
                              itemCount: photos.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 3 : 5,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: isMobile ? 0.92 : 1.05,
                                  ),
                              itemBuilder: (_, index) {
                                final p = photos[index];

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    InkWell(
                                      onTap: () => zoomPhoto(p),
                                      child: Container(
                                        decoration: AttachmentsStyles.cardStyle,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                child: Image.network(
                                                  _text(p['image_url']),
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                              child: Text(
                                                _text(
                                                      p['description'],
                                                    ).trim().isEmpty
                                                    ? 'No description'
                                                    : _text(p['description']),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AttachmentsStyles.small
                                                    .copyWith(
                                                      fontSize: isMobile
                                                          ? 9
                                                          : 11,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: AttachmentsStyles
                                                          .textPrimary,
                                                    ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 6,
                                                right: 6,
                                                bottom: 5,
                                              ),
                                              child: Text(
                                                _formatDate(p['created_at']),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AttachmentsStyles.small
                                                    .copyWith(
                                                      fontSize: isMobile
                                                          ? 8
                                                          : 10,
                                                      color: AttachmentsStyles
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        onTap: () async {
                                          await deletePhoto(p);
                                          refreshModal(() {});
                                        },
                                        child: Container(
                                          width: isMobile ? 24 : 30,
                                          height: isMobile ? 24 : 30,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.78,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AttachmentsStyles.danger
                                                  .withOpacity(0.9),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: const Color(0xFFFFB4B4),
                                            size: isMobile ? 15 : 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void zoomPhoto(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.90),
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.6,
                maxScale: 5,
                child: Image.network(_text(photo['image_url'])),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_text(photo['description']).trim().isNotEmpty)
                    Text(
                      _text(photo['description']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Text(
                    _formatDate(photo['created_at']),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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

  Widget _summaryCard({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 14,
        vertical: compact ? 7 : 12,
      ),
      decoration: BoxDecoration(
        color: AttachmentsStyles.bgDark.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 13 : 18),
          SizedBox(width: compact ? 5 : 7),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            label,
            style: AttachmentsStyles.small.copyWith(
              fontSize: compact ? 9 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required AttachmentsFilter value,
    required Color color,
    required IconData icon,
    required bool compact,
  }) {
    final active = selectedFilter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 15,
          vertical: compact ? 7 : 10,
        ),
        decoration: AttachmentsStyles.filterBox(active: active, color: color),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? color : AttachmentsStyles.gold,
              size: compact ? 13 : 16,
            ),
            SizedBox(width: compact ? 5 : 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : AttachmentsStyles.textSecondary,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topStatsAndFilters(bool compact) {
    final processing = _countStatus('processing');
    final collecting = _countStatus('collecting');
    final collected = _countStatus('collected');

    final currentLabel = selectedFilter == AttachmentsFilter.all
        ? 'All'
        : _collectingLabel(_filterName(selectedFilter));

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _summaryCard(
                  label: 'Processing',
                  value: processing,
                  color: AttachmentsStyles.gold,
                  icon: Icons.pending_actions_rounded,
                  compact: compact,
                ),
                const SizedBox(width: 8),
                _summaryCard(
                  label: 'Collecting',
                  value: collecting,
                  color: AttachmentsStyles.danger,
                  icon: Icons.local_shipping_outlined,
                  compact: compact,
                ),
                const SizedBox(width: 8),
                _summaryCard(
                  label: 'Collected',
                  value: collected,
                  color: Colors.grey,
                  icon: Icons.verified_rounded,
                  compact: compact,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: compact ? 38 : 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: AttachmentsStyles.filterBox(
            active: true,
            color: AttachmentsStyles.green,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AttachmentsFilter>(
              value: selectedFilter,
              dropdownColor: AttachmentsStyles.bgDark,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AttachmentsStyles.gold,
                size: 18,
              ),
              style: TextStyle(
                color: AttachmentsStyles.textPrimary,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w900,
              ),
              selectedItemBuilder: (_) {
                return AttachmentsFilter.values.map((_) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        color: AttachmentsStyles.green,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        currentLabel,
                        style: TextStyle(
                          color: AttachmentsStyles.green,
                          fontSize: compact ? 10 : 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: const [
                DropdownMenuItem(
                  value: AttachmentsFilter.all,
                  child: Text('All'),
                ),
                DropdownMenuItem(
                  value: AttachmentsFilter.processing,
                  child: Text('Processing'),
                ),
                DropdownMenuItem(
                  value: AttachmentsFilter.collecting,
                  child: Text('Collecting'),
                ),
                DropdownMenuItem(
                  value: AttachmentsFilter.collected,
                  child: Text('Collected'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => selectedFilter = v);
              },
            ),
          ),
        ),
      ],
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
                        onTap: () => viewPdf(order),
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
                        onTap: () => downloadPdf(order),
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
                        onTap: delivered ? () => viewPhotos(order) : () {},
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
                      onTap: () => viewPdf(order),
                    ),
                    const SizedBox(width: 8),
                    _iconBtn(
                      icon: Icons.download_rounded,
                      label: '',
                      onTap: () => downloadPdf(order),
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
                        onTap: () => viewPhotos(order),
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
