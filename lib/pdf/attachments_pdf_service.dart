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
  static String _money(dynamic v) => _num(v).toStringAsFixed(2);
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
          'stock_no, brand, unit, item_description, location, duration, quantity, unit_cost, total_cost',
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
                          width: 760,
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
      decoration: header ? const BoxDecoration(color: Color(0xFFEFEFEF)) : null,
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
                opacity: 0.045,
                child: pw.Image(
                  watermarkLogo,
                  width: 420,
                  height: 420,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ),
          build: (_) {
            final rows = items.asMap().entries.map((entry) {
              final i = entry.value;

              return [
                '${entry.key + 1}',
                '${_text(i['item_description'])}${(i['brand']?.toString().trim() ?? '').isNotEmpty ? '\nBrand: ${i['brand']}' : ''}',
                '${_text(i['quantity'])} ${_text(i['unit'])}',
                _money(i['unit_cost']),
                (i['duration']?.toString().trim().isNotEmpty ?? false)
                    ? _text(i['duration'])
                    : '-',
                _money(i['total_cost']),
              ];
            }).toList();

            return [
              _companyHeader(logoCircle, font, boldFont),
              pw.SizedBox(height: 12),
              pw.Container(
                height: 2.2,
                color: const PdfColor.fromInt(0xFFE5C76B),
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'PURCHASE ORDER',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 24),
              _labelValueRow('PURCHASE ORDER NO.', poNo, font, boldFont),
              _labelValueRow(
                'DATE',
                _dateLong(order['created_at']),
                font,
                boldFont,
              ),
              pw.SizedBox(height: 18),
              pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 1.2),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'PROCURING ENTITY INFORMATION',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              _infoRow('Procuring Entity Name', info.entity, font, boldFont),
              _infoRow(
                'Procuring Entity Address',
                info.address,
                font,
                boldFont,
              ),
              _infoRow('Contact Person', info.contact, font, boldFont),
              pw.SizedBox(height: 28),
              pw.Center(
                child: pw.Text(
                  'ORDER DETAILS',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(
                  color: const PdfColor.fromInt(0xFFB8CE8A),
                  width: 0.8,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFA5BF67),
                ),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  color: PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: pw.TextStyle(
                  font: font,
                  fontSize: 9.3,
                  color: PdfColors.black,
                ),
                cellPadding: const pw.EdgeInsets.all(7),
                headers: const [
                  'ITEM\nNO.',
                  'DESCRIPTION OF\nGOODS/SERVICES',
                  'QUANTITY',
                  'UNIT\nPRICE',
                  'DURATION',
                  'TOTAL',
                ],
                data: rows,
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.7),
                  1: pw.FlexColumnWidth(2.8),
                  2: pw.FlexColumnWidth(1.1),
                  3: pw.FlexColumnWidth(1.1),
                  4: pw.FlexColumnWidth(1.2),
                  5: pw.FlexColumnWidth(1.3),
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerRight,
                },
              ),
              _grandTotal(order['total_amount'], boldFont),
              pw.SizedBox(height: 36),
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
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(logo, width: 76, height: 76),
        pw.SizedBox(width: 18),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'MEGA PLUTO',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 27,
                color: const PdfColor.fromInt(0xFF1FAF7A),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
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
              style: pw.TextStyle(font: font, fontSize: 10.5),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _labelValueRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 28, bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 155,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
          ),
          pw.Text(':', style: pw.TextStyle(font: boldFont, fontSize: 12)),
          pw.SizedBox(width: 26),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12.5,
              color: label.contains('NO')
                  ? const PdfColor.fromInt(0xFFD42922)
                  : PdfColors.black,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 30, right: 20, bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 11.2),
            ),
          ),
          pw.Text(':', style: pw.TextStyle(font: font, fontSize: 11.2)),
          pw.SizedBox(width: 22),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '-' : value,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 11.2,
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFB8CE8A),
          width: 0.8,
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'GRAND TOTAL',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 18),
          pw.Text(
            _peso(amount),
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _receivedSection(pw.Font font, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 30),
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
