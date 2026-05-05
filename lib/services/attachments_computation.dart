// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttachmentsComputation {
  static const Color _blue = Color(0xFF0B2D4D);
  static const Color _gold = Color(0xFFE5C76B);
  static const Color _green = Color(0xFF1FAF7A);
  static const Color _cream = Color(0xFFF9F2D7);
  static const Color _muted = Color(0xFFC6B98F);
  static const Color _darkCard = Color(0xFF081711);

  static num _num(dynamic v) => num.tryParse(v?.toString() ?? '0') ?? 0;

  static String _money(dynamic value) {
    final n = _num(value);
    final parts = n.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '₱$whole.${parts[1]}';
  }

  static String _dateTime(dynamic value) {
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

  static Future<void> open({
    required BuildContext context,
    required Map<String, dynamic> order,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'comp_${order['id']}';

    final poController = TextEditingController(
      text: prefs.getString('${key}_po') ?? '',
    );

    final gasController = TextEditingController(
      text: prefs.getString('${key}_gas') ?? '',
    );

    final laborDeliveryController = TextEditingController(
      text:
          prefs.getString('${key}_labor_delivery') ??
          ((prefs.getString('${key}_labor') != null ||
                  prefs.getString('${key}_delivery') != null)
              ? (_num(prefs.getString('${key}_labor')) +
                        _num(prefs.getString('${key}_delivery')))
                    .toString()
              : ''),
    );

    final materialAmount = _num(order['total_amount']);
    final status = (order['collecting_status'] ?? 'processing').toString();
    final statusDate = order['status_datetime'];

    num poAmount = 0;
    num tax = 0;
    num gas = 0;
    num laborDelivery = 0;
    num net = 0;

    void compute() {
      poAmount = _num(poController.text);
      tax = poAmount * 0.07;
      gas = _num(gasController.text);
      laborDelivery = _num(laborDeliveryController.text);
      net = poAmount - tax - materialAmount - gas - laborDelivery;
    }

    Future<void> saveInputs() async {
      await prefs.setString('${key}_po', poController.text);
      await prefs.setString('${key}_gas', gasController.text);
      await prefs.setString(
        '${key}_labor_delivery',
        laborDeliveryController.text,
      );
    }

    compute();

    final result = await showDialog<_ComputationResult>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.80),
      builder: (_) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 650;
        final dialogWidth = isMobile ? width * 0.94 : 500.0;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void refresh() => setModalState(() => compute());

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 18,
                vertical: isMobile ? 10 : 18,
              ),
              child: Container(
                width: dialogWidth,
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF07140F), Color(0xFF0B1B13)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _gold, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/logo_circle.png',
                            width: isMobile ? 42 : 50,
                            height: isMobile ? 42 : 50,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Computation Report',
                                  style: TextStyle(
                                    color: _cream,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Purchase Order Net Computation',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _cream,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _green.withOpacity(0.45),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.pending_actions_rounded,
                              color: _green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: _green,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                _dateTime(statusDate),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _inputField(
                        controller: poController,
                        label: 'Purchase Order in Municipality',
                        icon: Icons.receipt_long_outlined,
                        onChanged: (_) async {
                          await saveInputs();
                          refresh();
                        },
                      ),

                      const SizedBox(height: 10),

                      _readonlyRow(
                        'Tax 7%',
                        _money(tax),
                        Icons.percent_rounded,
                      ),
                      _readonlyRow(
                        'Materials',
                        _money(materialAmount),
                        Icons.inventory_2_outlined,
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _inputField(
                              controller: gasController,
                              label: 'Gas',
                              icon: Icons.local_gas_station_outlined,
                              onChanged: (_) async {
                                await saveInputs();
                                refresh();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _inputField(
                              controller: laborDeliveryController,
                              label: 'Labor & Delivery',
                              icon: Icons.engineering_outlined,
                              onChanged: (_) async {
                                await saveInputs();
                                refresh();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF081711), // dark same sa cards
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _green, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'TOTAL NET',
                                style: TextStyle(
                                  color: Color(0xFFC6B98F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              _money(net),
                              style: TextStyle(
                                color: net < 0
                                    ? const Color(0xFFFF6B6B)
                                    : _green,
                                fontSize: isMobile ? 18 : 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _cream,
                                side: BorderSide(
                                  color: _gold.withOpacity(0.55),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                compute();
                                await saveInputs();

                                Navigator.pop(
                                  context,
                                  _ComputationResult(
                                    order: order,
                                    status: status,
                                    statusDate: statusDate,
                                    poAmount: poAmount,
                                    tax: tax,
                                    materials: materialAmount,
                                    gas: gas,
                                    laborDelivery: laborDelivery,
                                    totalNet: net,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _gold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              icon: const Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 17,
                              ),
                              label: const Text(
                                'Download PDF',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !context.mounted) return;
    await _downloadComputationPdf(result);
  }

  static Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        color: _cream,
        fontWeight: FontWeight.w900,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        prefixIcon: Icon(icon, color: _gold, size: 18),
        labelStyle: const TextStyle(
          color: _muted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _gold.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _gold, width: 1.2),
        ),
      ),
    );
  }

  static Widget _readonlyRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withOpacity(0.55)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _cream,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '- $value',
            style: const TextStyle(
              color: _muted,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadComputationPdf(_ComputationResult r) async {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoCircleBytes = await rootBundle.load('assets/logo_circle.png');

    final watermark = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final logoCircle = pw.MemoryImage(logoCircleBytes.buffer.asUint8List());

    const blue = PdfColor.fromInt(0xFF0B2D4D);
    const gold = PdfColor.fromInt(0xFFE5C76B);
    const green = PdfColor.fromInt(0xFF1FAF7A);
    const softBg = PdfColor.fromInt(0xFFFBFAF3);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        build: (_) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.045,
                    child: pw.Image(
                      watermark,
                      width: 420,
                      height: 420,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(28),
                decoration: pw.BoxDecoration(
                  color: softBg,
                  border: pw.Border.all(color: gold, width: 1),
                  borderRadius: pw.BorderRadius.circular(18),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Image(logoCircle, width: 58, height: 58),
                        pw.SizedBox(width: 14),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Computation Report',
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 24,
                                  color: blue,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'Purchase Order Net Computation',
                                style: pw.TextStyle(
                                  font: regular,
                                  fontSize: 10,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            border: pw.Border.all(color: green, width: 0.8),
                            borderRadius: pw.BorderRadius.circular(30),
                          ),
                          child: pw.Text(
                            r.status.toUpperCase(),
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 8,
                              color: green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 18),
                    pw.Container(height: 2, color: gold),
                    pw.SizedBox(height: 8),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Date: ${_dateTime(r.statusDate)}',
                        style: pw.TextStyle(
                          font: regular,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 34),
                    _pdfMainRow(
                      'Purchase Order in Municipality',
                      r.poAmount,
                      bold,
                      blue,
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'Deductions:',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 13,
                        color: blue,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _pdfDeductionRow('Tax 7%', r.tax, regular),
                    _pdfDeductionRow('Materials', r.materials, regular),
                    _pdfDeductionRow('Gas', r.gas, regular),
                    _pdfDeductionRow(
                      'Labor & Delivery',
                      r.laborDelivery,
                      regular,
                    ),
                    pw.SizedBox(height: 18),
                    pw.Container(height: 1.2, color: blue),
                    pw.SizedBox(height: 15),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        border: pw.Border.all(color: gold, width: 0.9),
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'TOTAL NET',
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 18,
                                color: blue,
                              ),
                            ),
                          ),
                          pw.Text(
                            _money(r.totalNet),
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 21,
                              color: r.totalNet < 0 ? PdfColors.red : green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Spacer(),
                    pw.Container(height: 1, color: gold),
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Text(
                        'Generated by MEGA PLUTO',
                        style: pw.TextStyle(
                          font: regular,
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Computation_Report.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _pdfMainRow(
    String label,
    num value,
    pw.Font font,
    PdfColor color,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 13.5, color: color),
          ),
        ),
        pw.Text(
          _money(value),
          style: pw.TextStyle(font: font, fontSize: 13.5, color: color),
        ),
      ],
    );
  }

  static pw.Widget _pdfDeductionRow(String label, num value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Text(
            '- ${_money(value)}',
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComputationResult {
  final Map<String, dynamic> order;
  final String status;
  final dynamic statusDate;
  final num poAmount;
  final num tax;
  final num materials;
  final num gas;
  final num laborDelivery;
  final num totalNet;

  const _ComputationResult({
    required this.order,
    required this.status,
    required this.statusDate,
    required this.poAmount,
    required this.tax,
    required this.materials,
    required this.gas,
    required this.laborDelivery,
    required this.totalNet,
  });
}
