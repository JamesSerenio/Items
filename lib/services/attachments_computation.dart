// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../styles/attachments_styles.dart';

class AttachmentsComputation {
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

    /// ✅ FIXED CONTROLLERS (NO DUPLICATE)
    final poController = TextEditingController(
      text: prefs.getString('${key}_po') ?? '',
    );
    final gasController = TextEditingController(
      text: prefs.getString('${key}_gas') ?? '',
    );
    final laborController = TextEditingController(
      text: prefs.getString('${key}_labor') ?? '',
    );
    final deliveryController = TextEditingController(
      text: prefs.getString('${key}_delivery') ?? '',
    );

    final materialAmount = _num(order['total_amount']);
    final status = (order['collecting_status'] ?? 'processing').toString();
    final statusDate = order['status_datetime'];

    num poAmount = 0;
    num tax = 0;
    num gas = 0;
    num labor = 0;
    num delivery = 0;
    num net = 0;

    void compute() {
      poAmount = _num(poController.text);
      tax = poAmount * 0.07;
      gas = _num(gasController.text);
      labor = _num(laborController.text);
      delivery = _num(deliveryController.text);

      net = poAmount - tax - materialAmount - gas - labor - delivery;
    }

    compute();

    final result = await showDialog<_ComputationResult>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            void refresh() {
              setState(() => compute());
            }

            Future<void> saveInputs() async {
              await prefs.setString('${key}_po', poController.text);
              await prefs.setString('${key}_gas', gasController.text);
              await prefs.setString('${key}_labor', laborController.text);
              await prefs.setString('${key}_delivery', deliveryController.text);
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF07140F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Computation Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _input(poController, 'Purchase Order', refresh, saveInputs),
                    _row('Tax 7%', _money(tax)),
                    _row('Materials', _money(materialAmount)),

                    _input(gasController, 'Gas', refresh, saveInputs),
                    _input(laborController, 'Labor', refresh, saveInputs),
                    _input(deliveryController, 'Delivery', refresh, saveInputs),

                    const SizedBox(height: 16),

                    Text(
                      'TOTAL NET: ${_money(net)}',
                      style: TextStyle(
                        color: net < 0 ? Colors.red : Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
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
                            labor: labor,
                            delivery: delivery,
                            totalNet: net,
                          ),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Download PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _downloadPdf(result);
    }
  }

  static Widget _input(
    TextEditingController c,
    String label,
    VoidCallback refresh,
    Future<void> Function() save,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        onChanged: (_) async {
          await save();
          refresh();
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.black12,
        ),
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value),
      ],
    );
  }

  /// 🔥 FIXED PDF (NO ERROR + WATERMARK)
  static Future<void> _downloadPdf(_ComputationResult r) async {
    final pdf = pw.Document();

    final logo = await rootBundle.load('assets/logo.png');
    final logoCircle = await rootBundle.load('assets/logo_circle.png');

    final watermark = pw.MemoryImage(logo.buffer.asUint8List());
    final circle = pw.MemoryImage(logoCircle.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Stack(
          children: [
            pw.Center(
              child: pw.Opacity(
                opacity: 0.05,
                child: pw.Image(watermark, width: 400),
              ),
            ),
            pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Image(circle, width: 50),
                    pw.Expanded(
                      child: pw.Center(
                        child: pw.Text(
                          'COMPUTATION REPORT',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                pw.Text('PO: ${_money(r.poAmount)}'),
                pw.Text('Tax: -${_money(r.tax)}'),
                pw.Text('Materials: -${_money(r.materials)}'),
                pw.Text('Gas: -${_money(r.gas)}'),
                pw.Text('Labor: -${_money(r.labor)}'),
                pw.Text('Delivery: -${_money(r.delivery)}'),

                pw.Divider(),

                pw.Text(
                  'TOTAL: ${_money(r.totalNet)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Computation_Report.pdf',
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
  final num labor;
  final num delivery;
  final num totalNet;

  _ComputationResult({
    required this.order,
    required this.status,
    required this.statusDate,
    required this.poAmount,
    required this.tax,
    required this.materials,
    required this.gas,
    required this.labor,
    required this.delivery,
    required this.totalNet,
  });
}
