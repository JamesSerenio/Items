import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttachmentsPdfService {
  static final supabase = Supabase.instance.client;

  static String _text(dynamic v) => v?.toString() ?? '-';

  static String _money(dynamic value) {
    final n = num.tryParse(value?.toString() ?? '0') ?? 0;
    return '₱${n.toStringAsFixed(2)}';
  }

  static String _formatDate(dynamic value) {
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

  static TableRow _tableRow(List<String> values, {bool header = false}) {
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
                                'ITEM DESCRIPTION / BRAND',
                                'LOCATION',
                                'QTY',
                                'UNIT COST',
                                'TOTAL COST',
                              ], header: true),
                              ...items.map(
                                (i) => _tableRow([
                                  _text(i['stock_no']),
                                  _text(i['unit']),
                                  '${_text(i['item_description'])}${(i['brand']?.toString().trim() ?? '').isNotEmpty ? '\nBrand: ${i['brand']}' : ''}',
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

  static pw.Widget _pdfCell(
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

  static Future<void> downloadPdf({required Map<String, dynamic> order}) async {
    final items = await _loadOrderItems(order['id'].toString());

    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 42, vertical: 34),
        build: (_) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.07,
                    child: pw.Image(
                      logoImage,
                      width: 620,
                      height: 620,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ),
              pw.Column(
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
                    children: [
                      pw.Spacer(),
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
                    border: pw.TableBorder.all(
                      color: PdfColors.grey700,
                      width: 0.8,
                    ),
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
                            'ITEM DESCRIPTION / BRAND',
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
                          _pdfCell(
                            'QTY',
                            bold: true,
                            font: font,
                            boldFont: boldFont,
                          ),
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
                              '${_text(i['item_description'])}${(i['brand']?.toString().trim() ?? '').isNotEmpty ? '\nBrand: ${i['brand']}' : ''}',
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
                      border: pw.Border.all(
                        color: PdfColors.grey700,
                        width: 0.8,
                      ),
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
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${_text(order['po_no'])}_purchase_order.pdf',
    );
  }
}
