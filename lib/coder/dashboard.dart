import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/dashboard_styles.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final data = await supabase.from('purchase_orders').select('''
        id,
        project_title,
        area_to_delivery,
        created_at,
        total_amount,
        collecting_status,
        purchase_order_items (
          id,
          stock_no,
          unit,
          item_description,
          location,
          supplier,
          quantity,
          unit_cost,
          total_cost,
          brand
        )
      ''');

      final list = List<Map<String, dynamic>>.from(data);

      list.sort((a, b) {
        final aRank = _statusRank(a['collecting_status']);
        final bRank = _statusRank(b['collecting_status']);
        if (aRank != bRank) return aRank.compareTo(bRank);

        final aDate =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(1900);
        final bDate =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(1900);

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        orders = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  int _statusRank(dynamic value) {
    final status = value?.toString().toLowerCase().trim() ?? '';
    if (status == 'processing' || status == 'proccessing') return 0;
    if (status == 'collecting') return 1;
    if (status == 'collected') return 2;
    return 3;
  }

  String _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return '-';
    return text;
  }

  String _money(dynamic value) {
    final amount = num.tryParse(value?.toString() ?? '0') ?? 0;
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return 'PHP $whole.${parts[1]}';
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '-';
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  String _dateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '-';

    final local = date.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
        ? 12
        : local.hour;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';

    return '${_date(value)} $hour:${local.minute.toString().padLeft(2, '0')} $ampm';
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> order) {
    final data = order['purchase_order_items'];
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }

  Future<void> _downloadOrderPdf(Map<String, dynamic> order) async {
    final orderedItems = _items(order);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'PURCHASE ORDER',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Project Title: ${_text(order['project_title'])}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Date: ${_dateTime(order['created_at'])}'),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: [
              'Stock No.',
              'Unit',
              'Item Description / Brand',
              'Location',
              'Supplier',
              'Qty',
              'Unit Cost',
              'Total Cost',
            ],
            data: orderedItems.map((item) {
              final desc = _text(item['item_description']);
              final brand = _text(item['brand']);

              return [
                _text(item['stock_no']),
                _text(item['unit']),
                brand == '-' ? desc : '$desc ($brand)',
                _text(item['location']),
                _text(item['supplier']),
                _text(item['quantity']),
                _money(item['unit_cost']),
                _money(item['total_cost']),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL AMOUNT: ${_money(order['total_amount'])}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    final Uint8List bytes = await doc.save();

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'purchase_order_${_text(order['project_title'])}.pdf',
    );
  }

  void _showOrderView(Map<String, dynamic> order) {
    final orderedItems = _items(order);

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(14),
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 28,
                      maxHeight: MediaQuery.of(context).size.height - 28,
                    ),
                    child: AspectRatio(
                      aspectRatio: 210 / 297,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'PURCHASE ORDER',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Project Title: ${_text(order['project_title'])}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Date: ${_dateTime(order['created_at'])}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Table(
                                  border: TableBorder.all(
                                    color: Colors.black54,
                                    width: 0.8,
                                  ),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.1),
                                    1: FlexColumnWidth(1.1),
                                    2: FlexColumnWidth(2.6),
                                    3: FlexColumnWidth(1.5),
                                    4: FlexColumnWidth(1.5),
                                    5: FlexColumnWidth(0.8),
                                    6: FlexColumnWidth(1.4),
                                    7: FlexColumnWidth(1.5),
                                  },
                                  children: [
                                    _tableRow([
                                      'STOCK\nNO.',
                                      'UNIT',
                                      'ITEM DESCRIPTION /\nBRAND',
                                      'LOCATION',
                                      'SUPPLIER',
                                      'QTY',
                                      'UNIT\nCOST',
                                      'TOTAL\nCOST',
                                    ], header: true),
                                    ...orderedItems.map((item) {
                                      final desc = _text(
                                        item['item_description'],
                                      );
                                      final brand = _text(item['brand']);

                                      return _tableRow([
                                        _text(item['stock_no']),
                                        _text(item['unit']),
                                        brand == '-' ? desc : '$desc ($brand)',
                                        _text(item['location']),
                                        _text(item['supplier']),
                                        _text(item['quantity']),
                                        _money(item['unit_cost']),
                                        _money(item['total_cost']),
                                      ]);
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                border: Border.all(color: Colors.black54),
                              ),
                              child: Text(
                                'TOTAL AMOUNT     ${_money(order['total_amount'])}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  TableRow _tableRow(List<String> cells, {bool header = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: header ? Colors.grey.shade200 : Colors.white,
      ),
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            cell,
            maxLines: header ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: header ? 9.5 : 9,
              fontWeight: header ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showItemsModal(Map<String, dynamic> order) {
    final orderedItems = _items(order);

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 650,
            constraints: const BoxConstraints(maxHeight: 620),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF07160F),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: DashboardStyles.plutoGold.withOpacity(0.75),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Items Ordered',
                        style: DashboardStyles.pageTitleStyle.copyWith(
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: DashboardStyles.plutoGold,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _text(order['project_title']),
                    style: DashboardStyles.pageSubtitleStyle,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: orderedItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(26),
                          child: Text(
                            'No ordered items found.',
                            style: DashboardStyles.pageSubtitleStyle,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: orderedItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final item = orderedItems[index];
                            final name = _text(item['item_description']);
                            final brand = _text(item['brand']);
                            final finalName = brand == '-'
                                ? name
                                : '$name ($brand)';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: DashboardStyles.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: DashboardStyles.plutoGold.withOpacity(
                                    0.35,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      finalName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: DashboardStyles.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Qty: ${_text(item['quantity'])}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: DashboardStyles.textSecondary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      _money(item['total_cost']),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: DashboardStyles.plutoGold,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
  }

  void _handleView(Map<String, dynamic> order) {
    _showOrderView(order);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: DashboardStyles.pageBackground,
      child: Container(
        margin: EdgeInsets.all(isMobile ? 8 : 16),
        padding: EdgeInsets.all(isMobile ? 12 : 26),
        decoration: isMobile
            ? DashboardStyles.mobilePanelDecoration
            : DashboardStyles.panelDecoration,
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: DashboardStyles.plutoGold,
                ),
              )
            : error != null
            ? Center(
                child: Text(
                  'Dashboard load failed:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: DashboardStyles.danger),
                ),
              )
            : RefreshIndicator(
                color: DashboardStyles.plutoGold,
                onRefresh: loadOrders,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: isMobile
                            ? DashboardStyles.pageTitleMobileStyle
                            : DashboardStyles.pageTitleStyle,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Purchase order summary list.',
                        style: DashboardStyles.pageSubtitleStyle,
                      ),
                      const SizedBox(height: 22),
                      _ResponsiveOrderList(
                        orders: orders,
                        items: _items,
                        text: _text,
                        money: _money,
                        date: _date,
                        onView: _handleView,
                        onItemsTap: _showItemsModal,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ResponsiveOrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> Function(Map<String, dynamic>) items;
  final String Function(dynamic) text;
  final String Function(dynamic) money;
  final String Function(dynamic) date;
  final void Function(Map<String, dynamic>) onView;
  final void Function(Map<String, dynamic>) onItemsTap;

  const _ResponsiveOrderList({
    required this.orders,
    required this.items,
    required this.text,
    required this.money,
    required this.date,
    required this.onView,
    required this.onItemsTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (orders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: DashboardStyles.panelCardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: DashboardStyles.plutoGold.withOpacity(0.55),
          ),
        ),
        child: const Center(
          child: Text(
            'No purchase orders found.',
            style: DashboardStyles.pageSubtitleStyle,
          ),
        ),
      );
    }

    if (width < 1200) {
      return Column(
        children: orders.map((order) {
          return _OrderCard(
            order: order,
            count: items(order).length,
            text: text,
            money: money,
            date: date,
            onView: () => onView(order),
            onItemsTap: () => onItemsTap(order),
          );
        }).toList(),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DashboardStyles.panelCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardStyles.plutoGold.withOpacity(0.65)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _TableHeader(),
            ...orders.map((order) {
              return _TableRowItem(
                order: order,
                count: items(order).length,
                text: text,
                money: money,
                date: date,
                onView: () => onView(order),
                onItemsTap: () => onItemsTap(order),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final int count;
  final String Function(dynamic) text;
  final String Function(dynamic) money;
  final String Function(dynamic) date;
  final VoidCallback onView;
  final VoidCallback onItemsTap;

  const _OrderCard({
    required this.order,
    required this.count,
    required this.text,
    required this.money,
    required this.date,
    required this.onView,
    required this.onItemsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardStyles.panelCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DashboardStyles.plutoGold.withOpacity(0.62)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text(order['project_title']),
            style: const TextStyle(
              color: DashboardStyles.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _InfoLine(label: 'Location', value: text(order['area_to_delivery'])),
          _InfoLine(label: 'Date', value: date(order['created_at'])),
          _InfoLine(label: 'Total', value: money(order['total_amount'])),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onItemsTap,
                child: _RoundBadge(
                  label: '$count items',
                  color: DashboardStyles.megaGreen,
                  wide: true,
                ),
              ),
              _StatusBadge(status: text(order['collecting_status'])),
              _ViewButton(
                onTap: onView,
                label: 'View',
                icon: Icons.visibility_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: DashboardStyles.plutoGold.withOpacity(0.15),
      child: const Row(
        children: [
          _HeadCell('Project Title', flex: 24),
          _HeadCell('Location', flex: 16),
          _HeadCell('Date Created', flex: 15),
          _HeadCell('Items', flex: 10),
          _HeadCell('Total', flex: 13),
          _HeadCell('Status', flex: 15),
          _HeadCell('View', flex: 10),
        ],
      ),
    );
  }
}

class _TableRowItem extends StatelessWidget {
  final Map<String, dynamic> order;
  final int count;
  final String Function(dynamic) text;
  final String Function(dynamic) money;
  final String Function(dynamic) date;
  final VoidCallback onView;
  final VoidCallback onItemsTap;

  const _TableRowItem({
    required this.order,
    required this.count,
    required this.text,
    required this.money,
    required this.date,
    required this.onView,
    required this.onItemsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: DashboardStyles.plutoGold.withOpacity(0.25)),
        ),
      ),
      child: Row(
        children: [
          _BodyCell(text(order['project_title']), flex: 24, bold: true),
          _BodyCell(text(order['area_to_delivery']), flex: 16),
          _BodyCell(date(order['created_at']), flex: 15),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onItemsTap,
                child: _RoundBadge(
                  label: '$count',
                  color: DashboardStyles.megaGreen,
                ),
              ),
            ),
          ),
          _BodyCell(
            money(order['total_amount']),
            flex: 13,
            bold: true,
            color: DashboardStyles.plutoGold,
          ),
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(status: text(order['collecting_status'])),
            ),
          ),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _ViewButton(
                onTap: onView,
                label: 'View',
                icon: Icons.visibility_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: DashboardStyles.pageSubtitleStyle.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: DashboardStyles.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  final String label;
  final int flex;

  const _HeadCell(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: DashboardStyles.smallGold.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool bold;
  final Color color;

  const _BodyCell(
    this.label, {
    required this.flex,
    this.bold = false,
    this.color = DashboardStyles.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool wide;

  const _RoundBadge({
    required this.label,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? null : 36,
      height: 36,
      padding: wide ? const EdgeInsets.symmetric(horizontal: 14) : null,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();

    Color color;
    String label;

    if (lower == 'processing' || lower == 'proccessing') {
      color = DashboardStyles.blue;
      label = 'processing';
    } else if (lower == 'collecting') {
      color = DashboardStyles.plutoGold;
      label = 'collecting';
    } else if (lower == 'collected') {
      color = DashboardStyles.megaGreen;
      label = 'collected';
    } else {
      color = DashboardStyles.textSecondary;
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const _ViewButton({
    required this.onTap,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: DashboardStyles.plutoGold,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(76, 38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}
