import 'package:flutter/material.dart';
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
    return '₱$whole.${parts[1]}';
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

    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '$hour:${local.minute.toString().padLeft(2, '0')} $ampm';
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> order) {
    final items = order['purchase_order_items'];
    if (items is List) return List<Map<String, dynamic>>.from(items);
    return [];
  }

  void _showOrderView(Map<String, dynamic> order) {
    final items = _items(order);

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 980,
            constraints: const BoxConstraints(maxHeight: 720),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'PURCHASE ORDER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
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
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Project Title: ${_text(order['project_title'])}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      'Date: ${_dateTime(order['created_at'])}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Location: ${_text(order['area_to_delivery'])}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    Text(
                      'Status: ${_text(order['collecting_status'])}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(color: Colors.black54),
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(2.4),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.5),
                        5: FlexColumnWidth(1),
                        6: FlexColumnWidth(1.4),
                        7: FlexColumnWidth(1.5),
                      },
                      children: [
                        _tableRow([
                          'STOCK NO.',
                          'UNIT',
                          'ITEM DESCRIPTION / BRAND',
                          'LOCATION',
                          'SUPPLIER',
                          'QTY',
                          'UNIT COST',
                          'TOTAL COST',
                        ], header: true),
                        ...items.map((item) {
                          final desc = _text(item['item_description']);
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
                  padding: const EdgeInsets.all(14),
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
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
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
          padding: const EdgeInsets.all(9),
          child: Text(
            cell,
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

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
                      _OrderTable(
                        orders: orders,
                        items: _items,
                        text: _text,
                        money: _money,
                        date: _date,
                        onView: _showOrderView,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _OrderTable extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> Function(Map<String, dynamic>) items;
  final String Function(dynamic) text;
  final String Function(dynamic) money;
  final String Function(dynamic) date;
  final void Function(Map<String, dynamic>) onView;

  const _OrderTable({
    required this.orders,
    required this.items,
    required this.text,
    required this.money,
    required this.date,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _empty();
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1180,
            child: Column(
              children: [
                _header(),
                ...orders.map((order) {
                  return _row(context, order);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DashboardStyles.panelCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardStyles.plutoGold.withOpacity(0.55)),
      ),
      child: const Center(
        child: Text(
          'No purchase orders found.',
          style: DashboardStyles.pageSubtitleStyle,
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      color: DashboardStyles.plutoGold.withOpacity(0.15),
      child: const Row(
        children: [
          _HeadCell('Project Title', flex: 3),
          _HeadCell('Location', flex: 2),
          _HeadCell('Date Created', flex: 2),
          _HeadCell('Items Ordered', flex: 1),
          _HeadCell('Total Amount', flex: 2),
          _HeadCell('Collecting Status', flex: 2),
          _HeadCell('View', flex: 1),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Map<String, dynamic> order) {
    final status = text(order['collecting_status']);
    final count = items(order).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: DashboardStyles.plutoGold.withOpacity(0.25)),
        ),
      ),
      child: Row(
        children: [
          _BodyCell(
            text(order['project_title']),
            flex: 3,
            bold: true,
            color: DashboardStyles.textPrimary,
          ),
          _BodyCell(text(order['area_to_delivery']), flex: 2),
          _BodyCell(date(order['created_at']), flex: 2),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RoundBadge(
                label: '$count',
                color: DashboardStyles.megaGreen,
              ),
            ),
          ),
          _BodyCell(
            money(order['total_amount']),
            flex: 2,
            bold: true,
            color: DashboardStyles.plutoGold,
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(status: status),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => onView(order),
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardStyles.plutoGold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
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
          fontSize: 14,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoundBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
