import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttachmentsPdfService {
  static final supabase = Supabase.instance.client;

  static String _text(dynamic v) => v?.toString() ?? '-';

  static num _num(dynamic v) => num.tryParse(v?.toString() ?? '0') ?? 0;

  static String _money(dynamic v) {
    final n = _num(v);
    final parts = n.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '$whole.${parts[1]}';
  }

  static String _peso(dynamic v) => '₱${_money(v)}';

  static String _dateLong(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '');
    if (d == null) return '-';

    final local = d.toLocal();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static Future<List<Map<String, dynamic>>> _loadOrderItems(
    String orderId,
  ) async {
    final items = await supabase
        .from('purchase_order_items')
        .select(
          'stock_no, brand, unit, item_description, location, quantity, unit_cost, total_cost',
        )
        .eq('purchase_order_id', orderId)
        .order('stock_no', ascending: true);

    return List<Map<String, dynamic>>.from(items);
  }

  static Future<String> _poNo(Map<String, dynamic> order) async {
    final data = await supabase
        .from('purchase_orders')
        .select('id, created_at')
        .order('created_at', ascending: true);

    final list = List<Map<String, dynamic>>.from(data);
    final index = list.indexWhere(
      (e) => e['id'].toString() == order['id'].toString(),
    );

    final number = index < 0 ? 1 : index + 1;
    return number.toString().padLeft(4, '0');
  }

  static Future<void> viewPdf({
    required BuildContext context,
    required Map<String, dynamic> order,
  }) async {
    final items = await _loadOrderItems(order['id'].toString());

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) {
        final isMobile = MediaQuery.of(context).size.width < 650;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.all(isMobile ? 10 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: isMobile ? double.infinity : 820,
            height: MediaQuery.of(context).size.height * 0.86,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'PURCHASE ORDER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Procuring Entity: ${_text(order['description'])}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Date: ${_dateLong(order['created_at'])}',
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
                          width: 780,
                          child: Column(
                            children: [
                              Table(
                                border: TableBorder.all(
                                  color: Colors.black54,
                                  width: 0.8,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(0.9),
                                  1: FlexColumnWidth(0.8),
                                  2: FlexColumnWidth(2.2),
                                  3: FlexColumnWidth(1.3),
                                  4: FlexColumnWidth(0.7),
                                  5: FlexColumnWidth(1.2),
                                  6: FlexColumnWidth(1.2),
                                },
                                children: [
                                  _flutterRow([
                                    'STOCK\nNO.',
                                    'UNIT',
                                    'ITEM DESCRIPTION /\nBRAND',
                                    'LOCATION',
                                    'QTY',
                                    'UNIT COST',
                                    'TOTAL COST',
                                  ], header: true),
                                  ...items.map(
                                    (i) => _flutterRow([
                                      _text(i['stock_no']),
                                      _text(i['unit']),
                                      '${_text(i['item_description'])}${(i['brand']?.toString().trim() ?? '').isNotEmpty ? '\nBrand: ${i['brand']}' : ''}',
                                      _text(i['location']),
                                      _text(i['quantity']),
                                      _peso(i['unit_cost']),
                                      _peso(i['total_cost']),
                                    ]),
                                  ),
                                ],
                              ),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEFEF),
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 0.8,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'TOTAL AMOUNT',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 28),
                                    Text(
                                      _peso(order['total_amount']),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
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

  static TableRow _flutterRow(List<String> values, {bool header = false}) {
    return TableRow(
      decoration: header
          ? const BoxDecoration(color: Color(0xFFEFEFEF))
          : const BoxDecoration(color: Colors.white),
      children: values.map((v) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            v,
            maxLines: 3,
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

  static Future<_ExtraInfo?> _openInfoDialog({
    required BuildContext context,
    required Map<String, dynamic> order,
  }) {
    final entityController = TextEditingController(
      text: (order['procuring_entity'] ?? order['description'] ?? '')
          .toString()
          .trim(),
    );
    final addressController = TextEditingController(
      text: (order['procuring_address'] ?? '').toString().trim(),
    );
    final contactController = TextEditingController(
      text: (order['contact_person'] ?? '').toString().trim(),
    );

    return showDialog<_ExtraInfo>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B1B13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE5C76B)),
        ),
        title: const Text(
          'Please fill the additional information',
          style: TextStyle(
            color: Color(0xFFF9F2D7),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoInput(
                controller: entityController,
                label: 'Procuring Entity Name',
              ),
              const SizedBox(height: 12),
              _InfoInput(
                controller: addressController,
                label: 'Procuring Entity Address',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _InfoInput(
                controller: contactController,
                label: 'Contact Person',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                _ExtraInfo(
                  entity: entityController.text.trim(),
                  address: addressController.text.trim(),
                  contact: contactController.text.trim(),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  static Future<void> downloadPdf({
    required BuildContext context,
    required Map<String, dynamic> order,
  }) async {
    try {
      final info = await _openInfoDialog(context: context, order: order);
      if (info == null) return;

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await supabase
          .from('purchase_orders')
          .update({
            'procuring_entity': info.entity,
            'procuring_address': info.address,
            'contact_person': info.contact,
          })
          .eq('id', order['id']);

      final items = await _loadOrderItems(order['id'].toString());
      final poNo = await _poNo(order);

      final font = await PdfGoogleFonts.notoSerifRegular();
      final boldFont = await PdfGoogleFonts.notoSerifBold();

      final logoCircleBytes = await rootBundle.load('assets/logo_circle.png');
      final logoBytes = await rootBundle.load('assets/logo.png');

      final logoCircle = pw.MemoryImage(logoCircleBytes.buffer.asUint8List());
      final watermarkLogo = pw.MemoryImage(logoBytes.buffer.asUint8List());

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      );

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(32, 24, 32, 34),
            buildBackground: (_) => pw.Center(
              child: pw.Opacity(
                opacity: 0.035,
                child: pw.Image(
                  watermarkLogo,
                  width: 920,
                  height: 920,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ),
          build: (_) {
            final rows = items.asMap().entries.map((entry) {
              final i = entry.value;

              return [
                _text(i['stock_no']).trim().isEmpty ||
                        _text(i['stock_no']) == '-'
                    ? '${entry.key + 1}'
                    : _text(i['stock_no']),
                _text(i['unit']),
                '${_text(i['item_description'])}${(i['brand']?.toString().trim() ?? '').isNotEmpty ? '\nBrand: ${i['brand']}' : ''}',
                _text(i['location']),
                _text(i['quantity']),
                _money(i['unit_cost']),
                _money(i['total_cost']),
              ];
            }).toList();

            return [
              _companyHeader(logoCircle, font, boldFont),
              pw.SizedBox(height: 10),
              pw.Container(
                height: 2.5,
                color: const PdfColor.fromInt(0xFFE5C76B),
              ),
              pw.SizedBox(height: 18),
              _sectionTitle('PURCHASE ORDER', boldFont),
              pw.SizedBox(height: 16),
              _poInfoBox(
                poNo: poNo,
                date: _dateLong(order['created_at']),
                font: font,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 14),
              _sectionTitle('PROCURING ENTITY INFORMATION', boldFont),
              pw.SizedBox(height: 12),
              _procuringBox(info, font, boldFont),
              pw.SizedBox(height: 18),
              _sectionTitle('ORDER DETAILS', boldFont),
              pw.SizedBox(height: 10),
              _orderTable(rows, font, boldFont),
              _grandTotal(order['total_amount'], boldFont),
              pw.SizedBox(height: 24),
              _receivedSection(font, boldFont),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      await Printing.sharePdf(bytes: bytes, filename: 'PO_$poNo.pdf');
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF download failed: $e'),
            backgroundColor: const Color(0xFF0B1B13),
          ),
        );
      }
    }
  }

  static pw.Widget _companyHeader(
    pw.ImageProvider logo,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Stack(
      children: [
        pw.Positioned(
          left: 22,
          top: 2,
          child: pw.Image(logo, width: 78, height: 78),
        ),
        pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'MEGA PLUTO',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 34,
                  color: const PdfColor.fromInt(0xFF1FAF7A),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Zone 1 - Sambulawan, Agusan, Cagayan de Oro City,',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 10.5),
              ),
              pw.Text(
                'Misamis Oriental, 9000',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 10.5),
              ),
              pw.Text(
                '09177727893',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: boldFont, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, pw.Font boldFont) {
    return pw.Center(
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static pw.Widget _poInfoBox({
    required String poNo,
    required String date,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF9FBF5),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFD8E7B7),
          width: 0.8,
        ),
      ),
      child: pw.Column(
        children: [
          _labelValueRow(
            'PURCHASE ORDER NO.',
            poNo,
            font,
            boldFont,
            isPo: true,
          ),
          pw.SizedBox(height: 4),
          _labelValueRow('DATE', date, font, boldFont),
        ],
      ),
    );
  }

  static pw.Widget _procuringBox(
    _ExtraInfo info,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFE5C76B),
          width: 0.75,
        ),
      ),
      child: pw.Column(
        children: [
          _infoRow('Procuring Entity Name', info.entity, font, boldFont),
          _infoRow('Procuring Entity Address', info.address, font, boldFont),
          _infoRow('Contact Person', info.contact, font, boldFont),
        ],
      ),
    );
  }

  static pw.Widget _orderTable(
    List<List<String>> rows,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFB8CE8A),
        width: 0.7,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF1FAF7A),
      ),
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FBF5),
      ),
      headerStyle: pw.TextStyle(
        font: boldFont,
        color: PdfColors.white,
        fontSize: 8.5,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      headers: const [
        'STOCK\nNO.',
        'UNIT',
        'ITEM DESCRIPTION /\nBRAND',
        'LOCATION',
        'QTY',
        'UNIT COST',
        'TOTAL COST',
      ],
      data: rows,
      columnWidths: const {
        0: pw.FlexColumnWidth(0.75),
        1: pw.FlexColumnWidth(0.85),
        2: pw.FlexColumnWidth(2.35),
        3: pw.FlexColumnWidth(1.25),
        4: pw.FlexColumnWidth(0.65),
        5: pw.FlexColumnWidth(1.15),
        6: pw.FlexColumnWidth(1.2),
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _labelValueRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont, {
    bool isPo = false,
  }) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 165,
          child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 11)),
        ),
        pw.Text(':', style: pw.TextStyle(font: boldFont, fontSize: 11)),
        pw.SizedBox(width: 22),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 11.5,
            color: isPo ? const PdfColor.fromInt(0xFFD42922) : PdfColors.black,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 165,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 10.7),
            ),
          ),
          pw.Text(':', style: pw.TextStyle(font: font, fontSize: 10.7)),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '-' : value,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10.7,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _grandTotal(dynamic amount, pw.Font boldFont) {
    return pw.Container(
      height: 42,
      padding: const pw.EdgeInsets.symmetric(horizontal: 13),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FBF5),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFB8CE8A),
          width: 0.7,
        ),
        borderRadius: const pw.BorderRadius.only(
          bottomLeft: pw.Radius.circular(8),
          bottomRight: pw.Radius.circular(8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'GRAND TOTAL',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 28),
          pw.Text(
            _peso(amount),
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _receivedSection(pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF9FBF5),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFD8E7B7),
          width: 0.8,
        ),
      ),
      child: pw.Column(
        children: [
          _infoRow('Received by', 'JAMES M. SERENIO', font, boldFont),
          _infoRow('Designation', 'Authorized Representative', font, boldFont),
          _infoRow('Name of Firm', 'MEGA PLUTO', font, boldFont),
        ],
      ),
    );
  }
}

class _ExtraInfo {
  final String entity;
  final String address;
  final String contact;

  const _ExtraInfo({
    required this.entity,
    required this.address,
    required this.contact,
  });
}

class _InfoInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _InfoInput({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFFF9F2D7)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFE5C76B)),
        filled: true,
        fillColor: const Color(0xFF07140F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: const Color(0xFFE5C76B).withOpacity(0.45),
          ),
        ),
      ),
    );
  }
}
