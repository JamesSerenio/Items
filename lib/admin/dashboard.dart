import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/dashboard_styles.dart';

enum DashboardFilter { day, week, month, year }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? error;

  DashboardFilter selectedFilter = DashboardFilter.day;

  DateTime? customStartDate;
  DateTime? customEndDate;

  String? selectedSupplier;

  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final ordersData = await supabase
          .from('purchase_orders')
          .select(
            'id, po_no, description, item_description, total_amount, created_at',
          )
          .order('created_at', ascending: false);

      final itemData = await supabase.from('purchase_order_items').select('''
  id,
  purchase_order_id,
  material_id,
  item_description,
  quantity,
  total_cost,
  location,
  materials (
    supplier_name
  ),
  purchase_orders (
    created_at
  )
''');

      if (!mounted) return;

      setState(() {
        orders = List<Map<String, dynamic>>.from(ordersData);
        items = List<Map<String, dynamic>>.from(itemData);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  num _num(dynamic v) => num.tryParse(v?.toString() ?? '0') ?? 0;

  String _money(num value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '₱$whole.${parts[1]}';
  }

  DateTime? _date(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    return d?.toLocal();
  }

  String _supplier(Map<String, dynamic> item) {
    final material = item['materials'];
    if (material is Map && material['supplier_name'] != null) {
      final name = material['supplier_name'].toString().trim();
      if (name.isNotEmpty) return name;
    }
    return 'Unknown Supplier';
  }

  String _itemName(Map<String, dynamic> item) {
    final name = item['item_description']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Unnamed Item';
  }

  DateTime _startDate() {
    if (customStartDate != null) {
      return DateTime(
        customStartDate!.year,
        customStartDate!.month,
        customStartDate!.day,
      );
    }

    final now = DateTime.now();

    switch (selectedFilter) {
      case DashboardFilter.day:
        return DateTime(now.year, now.month, now.day);
      case DashboardFilter.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(start.year, start.month, start.day);
      case DashboardFilter.month:
        return DateTime(now.year, now.month, 1);
      case DashboardFilter.year:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime _endDate() {
    if (customEndDate != null) {
      return DateTime(
        customEndDate!.year,
        customEndDate!.month,
        customEndDate!.day + 1,
      );
    }

    final now = DateTime.now();

    switch (selectedFilter) {
      case DashboardFilter.day:
        return DateTime(now.year, now.month, now.day + 1);
      case DashboardFilter.week:
        return _startDate().add(const Duration(days: 7));
      case DashboardFilter.month:
        return DateTime(now.year, now.month + 1, 1);
      case DashboardFilter.year:
        return DateTime(now.year + 1, 1, 1);
    }
  }

  List<Map<String, dynamic>> get filteredItems {
    final start = _startDate();
    final end = _endDate();

    return items.where((i) {
      final po = i['purchase_orders'];
      if (po is! Map) return false;

      final d = _date(po['created_at']);
      if (d == null) return false;

      return !d.isBefore(start) && d.isBefore(end);
    }).toList();
  }

  List<String> get suppliers {
    final list = filteredItems.map(_supplier).toSet().toList();
    list.sort();
    return list;
  }

  List<Map<String, dynamic>> get selectedSupplierItems {
    if (selectedSupplier == null || selectedSupplier!.isEmpty) return [];
    return filteredItems
        .where((item) => _supplier(item) == selectedSupplier)
        .toList();
  }

  num get selectedSupplierTotal {
    return selectedSupplierItems.fold<num>(
      0,
      (sum, item) => sum + _num(item['total_cost']),
    );
  }

  int get totalSuppliers {
    return filteredItems
        .map(_supplier)
        .where((s) => s.isNotEmpty)
        .toSet()
        .length;
  }

  int get totalMaterials {
    return filteredItems
        .map((i) => i['material_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;
  }

  num get totalAmount {
    return filteredItems.fold<num>(0, (sum, i) => sum + _num(i['total_cost']));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: customStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DashboardStyles.plutoGold,
              onPrimary: Colors.black,
              surface: Color(0xFF081711),
              onSurface: DashboardStyles.textPrimary,
            ),
            dialogTheme: const DialogThemeData(insetPadding: EdgeInsets.zero),
          ),
          child: Center(
            child: Transform.scale(
              scale: 0.740, // paliitin mo pa: 0.68 / 0.65
              child: child!,
            ),
          ),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      customStartDate = picked;
      if (customEndDate != null && customEndDate!.isBefore(picked)) {
        customEndDate = picked;
      }
      selectedSupplier = null;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: customEndDate ?? customStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DashboardStyles.plutoGold,
              onPrimary: Colors.black,
              surface: Color(0xFF081711),
              onSurface: DashboardStyles.textPrimary,
            ),
            dialogTheme: const DialogThemeData(insetPadding: EdgeInsets.zero),
          ),
          child: Center(child: Transform.scale(scale: 0.740, child: child!)),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      customEndDate = picked;
      if (customStartDate != null && customStartDate!.isAfter(picked)) {
        customStartDate = picked;
      }
      selectedSupplier = null;
    });
  }

  void _clearCustomDate() {
    setState(() {
      customStartDate = null;
      customEndDate = null;
      selectedSupplier = null;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<_LinePoint> get lineData {
    final now = DateTime.now();
    final points = <_LinePoint>[];

    if (selectedFilter == DashboardFilter.day) {
      for (int h = 0; h < 24; h += 4) {
        final label = '${h.toString().padLeft(2, '0')}:00';

        final bucket = filteredItems.where((i) {
          final po = i['purchase_orders'];
          final d = po is Map ? _date(po['created_at']) : null;
          return d != null && d.hour >= h && d.hour < h + 4;
        });

        points.add(
          _LinePoint(
            label,
            bucket.fold<num>(0, (s, i) => s + _num(i['total_cost'])),
          ),
        );
      }
    } else if (selectedFilter == DashboardFilter.week) {
      final start = _startDate();

      for (int i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        final label = '${day.month}/${day.day}';

        final bucket = filteredItems.where((item) {
          final po = item['purchase_orders'];
          final d = po is Map ? _date(po['created_at']) : null;

          return d != null &&
              d.year == day.year &&
              d.month == day.month &&
              d.day == day.day;
        });

        points.add(
          _LinePoint(
            label,
            bucket.fold<num>(0, (s, i) => s + _num(i['total_cost'])),
          ),
        );
      }
    } else if (selectedFilter == DashboardFilter.month) {
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      final ranges = [
        [1, 7],
        [8, 14],
        [15, 21],
        [22, lastDay],
      ];

      for (final r in ranges) {
        final bucket = filteredItems.where((item) {
          final po = item['purchase_orders'];
          final d = po is Map ? _date(po['created_at']) : null;
          return d != null && d.day >= r[0] && d.day <= r[1];
        });

        points.add(
          _LinePoint(
            '${r[0]}-${r[1]}',
            bucket.fold<num>(0, (s, i) => s + _num(i['total_cost'])),
          ),
        );
      }
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      for (int m = 1; m <= 12; m++) {
        final bucket = filteredItems.where((item) {
          final po = item['purchase_orders'];
          final d = po is Map ? _date(po['created_at']) : null;
          return d != null && d.month == m;
        });

        points.add(
          _LinePoint(
            months[m - 1],
            bucket.fold<num>(0, (s, i) => s + _num(i['total_cost'])),
          ),
        );
      }
    }

    return points;
  }

  List<_SupplierStat> get supplierStats {
    final map = <String, _SupplierStat>{};

    for (final item in filteredItems) {
      final supplier = _supplier(item);
      final qty = _num(item['quantity']).toInt();
      final amount = _num(item['total_cost']);

      map.putIfAbsent(supplier, () => _SupplierStat(supplier, 0, 0));
      map[supplier] = _SupplierStat(
        supplier,
        map[supplier]!.items + qty,
        map[supplier]!.amount + amount,
      );
    }

    final list = map.values.where((s) => s.items > 0).toList();
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  String get filterLabel {
    if (customStartDate != null || customEndDate != null) {
      return '${_formatDate(customStartDate)} to ${_formatDate(customEndDate)}';
    }

    switch (selectedFilter) {
      case DashboardFilter.day:
        return 'Today';
      case DashboardFilter.week:
        return 'This Week';
      case DashboardFilter.month:
        return 'This Month';
      case DashboardFilter.year:
        return 'This Year';
    }
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
        padding: EdgeInsets.all(isMobile ? 10 : 24),
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
                onRefresh: loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        isMobile: isMobile,
                        selected: selectedFilter,
                        hasCustomDate:
                            customStartDate != null || customEndDate != null,
                        onChanged: (v) {
                          setState(() {
                            selectedFilter = v;
                            customStartDate = null;
                            customEndDate = null;
                            selectedSupplier = null;
                          });
                        },
                      ),
                      SizedBox(height: isMobile ? 10 : 18),
                      _DateFilterBox(
                        isMobile: isMobile,
                        startDate: _formatDate(customStartDate),
                        endDate: _formatDate(customEndDate),
                        onStartTap: _pickStartDate,
                        onEndTap: _pickEndDate,
                        onClear: _clearCustomDate,
                      ),
                      SizedBox(height: isMobile ? 10 : 18),
                      Row(
                        children: [
                          Expanded(
                            child: _StatMiniCard(
                              icon: Icons.storefront_rounded,
                              title: 'Supplier',
                              value: '$totalSuppliers',
                              color: DashboardStyles.megaGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _StatMiniCard(
                              icon: Icons.inventory_2_rounded,
                              title: 'Materials',
                              value: '$totalMaterials',
                              color: DashboardStyles.plutoGold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _StatMiniCard(
                              icon: Icons.payments_rounded,
                              title: 'Amount',
                              value: _money(totalAmount),
                              color: DashboardStyles.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 10 : 18),
                      _SupplierOrderPanel(
                        isMobile: isMobile,
                        suppliers: suppliers,
                        selectedSupplier: selectedSupplier,
                        selectedItems: selectedSupplierItems,
                        selectedTotal: selectedSupplierTotal,
                        money: _money,
                        itemName: _itemName,
                        numValue: _num,
                        onSupplierChanged: (value) {
                          setState(() {
                            selectedSupplier = value;
                          });
                        },
                      ),
                      SizedBox(height: isMobile ? 10 : 18),
                      if (isMobile) ...[
                        _Panel(
                          title: 'Purchase Amount Trend',
                          subtitle: 'Total amount ordered for $filterLabel.',
                          child: SizedBox(
                            height: 125,
                            child: _LineChart(points: lineData),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _Panel(
                          title: 'Supplier Amount Orders',
                          subtitle: 'Total amount ordered per supplier.',
                          child: SizedBox(
                            height: 150,
                            child: _BarChart(stats: supplierStats),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _Panel(
                          title: 'Supplier Share',
                          subtitle: 'Percentage and total amount per supplier.',
                          child: _DonutSection(stats: supplierStats),
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _Panel(
                                title: 'Purchase Amount Trend',
                                subtitle:
                                    'Total amount ordered for $filterLabel.',
                                child: SizedBox(
                                  height: 260,
                                  child: _LineChart(points: lineData),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _Panel(
                                title: 'Supplier Amount Orders',
                                subtitle: 'Total amount ordered per supplier.',
                                child: SizedBox(
                                  height: 260,
                                  child: _BarChart(stats: supplierStats),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Panel(
                          title: 'Supplier Share',
                          subtitle: 'Percentage and total amount per supplier.',
                          child: _DonutSection(stats: supplierStats),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DateFilterBox extends StatelessWidget {
  final bool isMobile;
  final String startDate;
  final String endDate;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  final VoidCallback onClear;

  const _DateFilterBox({
    required this.isMobile,
    required this.startDate,
    required this.endDate,
    required this.onStartTap,
    required this.onEndTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      _DateButton(
        label: 'Start Date',
        value: startDate,
        icon: Icons.calendar_month_rounded,
        onTap: onStartTap,
      ),
      SizedBox(width: isMobile ? 4 : 10),
      _DateButton(
        label: 'End Date',
        value: endDate,
        icon: Icons.event_available_rounded,
        onTap: onEndTap,
      ),
      SizedBox(width: isMobile ? 4 : 10),
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onClear,
        child: Container(
          height: isMobile ? 38 : 52,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
          decoration: BoxDecoration(
            color: DashboardStyles.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardStyles.danger.withOpacity(0.55)),
          ),
          child: Icon(
            Icons.close_rounded,
            color: DashboardStyles.danger,
            size: isMobile ? 18 : 22,
          ),
        ),
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: DashboardStyles.panelCardColor,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
        border: Border.all(color: DashboardStyles.plutoGold.withOpacity(0.55)),
      ),
      child: Row(
        children: [
          Expanded(child: children[0]),
          SizedBox(width: isMobile ? 6 : 10),
          Expanded(child: children[2]),
          SizedBox(width: isMobile ? 6 : 10),
          children[4],
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: isMobile ? 38 : 52,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 14),
        decoration: BoxDecoration(
          color: DashboardStyles.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DashboardStyles.plutoGold.withOpacity(0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: DashboardStyles.plutoGold,
              size: isMobile ? 13 : 18,
            ),
            SizedBox(width: isMobile ? 4 : 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: DashboardStyles.pageSubtitleStyle.copyWith(
                      fontSize: isMobile ? 8.5 : 10,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardStyles.smallGold.copyWith(
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierOrderPanel extends StatelessWidget {
  final bool isMobile;
  final List<String> suppliers;
  final String? selectedSupplier;
  final List<Map<String, dynamic>> selectedItems;
  final num selectedTotal;
  final String Function(num) money;
  final String Function(Map<String, dynamic>) itemName;
  final num Function(dynamic) numValue;
  final ValueChanged<String?> onSupplierChanged;

  const _SupplierOrderPanel({
    required this.isMobile,
    required this.suppliers,
    required this.selectedSupplier,
    required this.selectedItems,
    required this.selectedTotal,
    required this.money,
    required this.itemName,
    required this.numValue,
    required this.onSupplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Supplier Ordered Items',
      subtitle: 'Tap/select supplier to view ordered items, qty, and total.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: isMobile ? 48 : 56,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14),
            decoration: BoxDecoration(
              color: DashboardStyles.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DashboardStyles.plutoGold.withOpacity(0.55),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSupplier,
                isExpanded: true,
                dropdownColor: const Color(0xFF081711),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: DashboardStyles.plutoGold,
                ),
                hint: Text(
                  suppliers.isEmpty ? 'No supplier found' : 'Select Supplier',
                  style: DashboardStyles.pageSubtitleStyle.copyWith(
                    fontSize: isMobile ? 11 : 13,
                  ),
                ),
                items: suppliers.map((supplier) {
                  return DropdownMenuItem<String>(
                    value: supplier,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: DashboardStyles.plutoGold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            supplier,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: DashboardStyles.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onSupplierChanged,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 10 : 14),
          if (selectedSupplier == null)
            const SizedBox(
              height: 90,
              child: _EmptyChart(
                message: 'Please select supplier to view ordered items.',
              ),
            )
          else if (selectedItems.isEmpty)
            const SizedBox(
              height: 90,
              child: _EmptyChart(
                message: 'No ordered items for this supplier.',
              ),
            )
          else
            _SupplierItemsTable(
              isMobile: isMobile,
              items: selectedItems,
              selectedTotal: selectedTotal,
              money: money,
              itemName: itemName,
              numValue: numValue,
            ),
        ],
      ),
    );
  }
}

class _SupplierItemsTable extends StatelessWidget {
  final bool isMobile;
  final List<Map<String, dynamic>> items;
  final num selectedTotal;
  final String Function(num) money;
  final String Function(Map<String, dynamic>) itemName;
  final num Function(dynamic) numValue;

  const _SupplierItemsTable({
    required this.isMobile,
    required this.items,
    required this.selectedTotal,
    required this.money,
    required this.itemName,
    required this.numValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardStyles.cardColor.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardStyles.plutoGold.withOpacity(0.38)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: DashboardStyles.plutoGold.withOpacity(0.13),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Item Name',
                    style: DashboardStyles.smallGold.copyWith(
                      fontSize: isMobile ? 9 : 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: DashboardStyles.smallGold.copyWith(
                      fontSize: isMobile ? 9 : 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.right,
                    style: DashboardStyles.smallGold.copyWith(
                      fontSize: isMobile ? 9 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: isMobile ? 210 : 260),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: DashboardStyles.plutoGold.withOpacity(0.15),
              ),
              itemBuilder: (_, index) {
                final item = items[index];
                final qty = numValue(item['quantity']);
                final total = numValue(item['total_cost']);

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 8 : 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          itemName(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: DashboardStyles.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: isMobile ? 10 : 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DashboardStyles.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: isMobile ? 10 : 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          money(total),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: DashboardStyles.plutoGold,
                            fontWeight: FontWeight.w900,
                            fontSize: isMobile ? 10 : 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: DashboardStyles.megaGreen.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(
                  color: DashboardStyles.plutoGold.withOpacity(0.24),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Amount',
                    style: TextStyle(
                      color: DashboardStyles.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 11 : 14,
                    ),
                  ),
                ),
                Text(
                  money(selectedTotal),
                  style: TextStyle(
                    color: DashboardStyles.plutoGold,
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 13 : 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatMiniCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      height: isMobile ? 78 : 110,
      padding: EdgeInsets.all(isMobile ? 8 : 14),
      decoration: BoxDecoration(
        color: DashboardStyles.cardColor,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
        border: Border.all(color: DashboardStyles.plutoGold.withOpacity(0.65)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isMobile ? 16 : 22),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            title,
            style: DashboardStyles.cardTitleStyle.copyWith(
              fontSize: isMobile ? 8.5 : 11,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: DashboardStyles.cardValueStyle.copyWith(
                fontSize: isMobile ? 13 : 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;
  final DashboardFilter selected;
  final bool hasCustomDate;
  final ValueChanged<DashboardFilter> onChanged;

  const _Header({
    required this.isMobile,
    required this.selected,
    required this.hasCustomDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: isMobile
              ? DashboardStyles.pageTitleMobileStyle
              : DashboardStyles.pageTitleStyle,
        ),
        SizedBox(height: isMobile ? 5 : 8),
        const Text(
          'Premium overview of supplier orders, materials, and purchase amount.',
          style: DashboardStyles.pageSubtitleStyle,
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _FilterPills(
          selected: selected,
          onChanged: onChanged,
          isMobile: isMobile,
          hasCustomDate: hasCustomDate,
        ),
      ],
    );
  }
}

class _FilterPills extends StatelessWidget {
  final DashboardFilter selected;
  final ValueChanged<DashboardFilter> onChanged;
  final bool isMobile;
  final bool hasCustomDate;

  const _FilterPills({
    required this.selected,
    required this.onChanged,
    required this.isMobile,
    required this.hasCustomDate,
  });

  @override
  Widget build(BuildContext context) {
    final data = {
      DashboardFilter.day: 'Day',
      DashboardFilter.week: 'Week',
      DashboardFilter.month: 'Month',
      DashboardFilter.year: 'Year',
    };

    return Wrap(
      spacing: isMobile ? 6 : 8,
      runSpacing: isMobile ? 6 : 8,
      children: data.entries.map((e) {
        final active = !hasCustomDate && selected == e.key;

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 7 : 10,
            ),
            decoration: BoxDecoration(
              color: active
                  ? DashboardStyles.plutoGold.withOpacity(0.20)
                  : DashboardStyles.cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active
                    ? DashboardStyles.plutoGold
                    : DashboardStyles.plutoGold.withOpacity(0.35),
              ),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: active
                    ? DashboardStyles.plutoGold
                    : DashboardStyles.textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: isMobile ? 10 : 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 10 : 20),
      decoration: BoxDecoration(
        color: DashboardStyles.panelCardColor,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 26),
        border: Border.all(color: DashboardStyles.plutoGold.withOpacity(0.68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DashboardStyles.panelTitleStyle),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            subtitle,
            style: DashboardStyles.pageSubtitleStyle.copyWith(
              fontSize: isMobile ? 10 : 12,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
          child,
        ],
      ),
    );
  }
}

class _LinePoint {
  final String label;
  final num amount;

  _LinePoint(this.label, this.amount);
}

class _SupplierStat {
  final String supplier;
  final int items;
  final num amount;

  _SupplierStat(this.supplier, this.items, this.amount);
}

class _LineChart extends StatelessWidget {
  final List<_LinePoint> points;

  const _LineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((p) => p.amount > 0);

    if (!hasData) {
      return const _EmptyChart(message: 'No purchase amount yet.');
    }

    return CustomPaint(painter: _LineAmountPainter(points), child: Container());
  }
}

class _LineAmountPainter extends CustomPainter {
  final List<_LinePoint> points;

  _LineAmountPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0;
    const right = 6.0;
    const top = 8.0;
    const bottom = 22.0;

    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;

    final grid = Paint()
      ..color = DashboardStyles.plutoGold.withOpacity(0.10)
      ..strokeWidth = 1;

    final line = Paint()
      ..shader = const LinearGradient(
        colors: [DashboardStyles.megaGreen, DashboardStyles.plutoGold],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final text = TextPainter(textDirection: TextDirection.ltr);

    final maxValue = math.max(
      1,
      points.map((p) => p.amount.toDouble()).fold<double>(0, math.max),
    );

    for (int i = 0; i <= 3; i++) {
      final y = top + (chartH / 3) * i;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);

      final value = maxValue - ((maxValue / 3) * i);

      text.text = TextSpan(
        text: value >= 1000
            ? '₱${(value / 1000).toStringAsFixed(1)}k'
            : '₱${value.toStringAsFixed(0)}',
        style: const TextStyle(
          color: DashboardStyles.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      );
      text.layout(maxWidth: 34);
      text.paint(canvas, Offset(0, y - 5));
    }

    Offset getPoint(int index) {
      final x = left + (chartW / math.max(1, points.length - 1)) * index;
      final y =
          top +
          chartH -
          ((points[index].amount.toDouble() / maxValue) * chartH);
      return Offset(x, y);
    }

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final p = getPoint(i);

      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }

      text.text = TextSpan(
        text: points[i].label,
        style: const TextStyle(
          color: DashboardStyles.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      );
      text.layout(maxWidth: 40);
      text.paint(canvas, Offset(p.dx - text.width / 2, size.height - 15));
    }

    canvas.drawPath(path, line);

    for (int i = 0; i < points.length; i++) {
      final p = getPoint(i);
      canvas.drawCircle(p, 3.2, Paint()..color = DashboardStyles.plutoGold);
      canvas.drawCircle(p, 1.6, Paint()..color = DashboardStyles.cardColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChart extends StatelessWidget {
  final List<_SupplierStat> stats;

  const _BarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty || stats.every((e) => e.amount <= 0)) {
      return const _EmptyChart(message: 'No supplier amount yet.');
    }

    return CustomPaint(
      painter: _VerticalAmountBarPainter(stats),
      child: Container(),
    );
  }
}

class _VerticalAmountBarPainter extends CustomPainter {
  final List<_SupplierStat> stats;

  _VerticalAmountBarPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 25.0;

    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;

    final maxAmount = math.max(
      1,
      stats.map((e) => e.amount.toDouble()).fold<double>(0, math.max),
    );

    final gridPaint = Paint()
      ..color = DashboardStyles.plutoGold.withOpacity(0.12)
      ..strokeWidth = 1;

    final text = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 4; i++) {
      final y = top + (chartH / 4) * i;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );

      final value = maxAmount - ((maxAmount / 4) * i);

      text.text = TextSpan(
        text: value >= 1000
            ? '₱${(value / 1000).toStringAsFixed(1)}k'
            : '₱${value.toStringAsFixed(0)}',
        style: const TextStyle(
          color: DashboardStyles.textSecondary,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      );
      text.layout(maxWidth: 35);
      text.paint(canvas, Offset(0, y - 5));
    }

    final count = stats.length;
    final slotW = chartW / count;
    final barW = math.min(24.0, slotW * 0.42);

    for (int i = 0; i < count; i++) {
      final s = stats[i];
      final ratio = s.amount.toDouble() / maxAmount;
      final barH = math.max(2.0, chartH * ratio);

      final x = left + (slotW * i) + (slotW - barW) / 2;
      final y = top + chartH - barH;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, barH),
        const Radius.circular(5),
      );

      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [DashboardStyles.megaGreen, DashboardStyles.plutoGold],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(x, y, barW, barH));

      canvas.drawRRect(rect, paint);

      text.text = TextSpan(
        text: _formatMoneyShort(s.amount),
        style: const TextStyle(
          color: DashboardStyles.plutoGold,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
        ),
      );
      text.layout(maxWidth: slotW);
      text.paint(canvas, Offset(x + (barW - text.width) / 2, y - 12));

      final supplierLabel = s.supplier.length > 6
          ? s.supplier.substring(0, 6)
          : s.supplier;

      text.text = TextSpan(
        text: supplierLabel,
        style: const TextStyle(
          color: DashboardStyles.textSecondary,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      );
      text.layout(maxWidth: slotW);
      text.paint(
        canvas,
        Offset(left + (slotW * i) + (slotW - text.width) / 2, size.height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutSection extends StatelessWidget {
  final List<_SupplierStat> stats;

  const _DonutSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalItems = stats.fold<int>(0, (s, e) => s + e.items);
    final totalAmount = stats.fold<num>(0, (s, e) => s + e.amount);

    if (stats.isEmpty || totalItems == 0) {
      return const SizedBox(
        height: 130,
        child: _EmptyChart(message: 'No supplier percentage yet.'),
      );
    }

    final colors = [
      DashboardStyles.plutoGold,
      DashboardStyles.megaGreen,
      DashboardStyles.blue,
      DashboardStyles.danger,
      DashboardStyles.plutoGoldDeep,
      DashboardStyles.megaGreenSoft,
    ];

    final isMobile = MediaQuery.of(context).size.width < 768;

    if (!isMobile) {
      return SizedBox(
        height: 210,
        child: Row(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _DonutPainter(
                  stats: stats,
                  colors: colors,
                  strokeWidth: 20,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalItems',
                        style: DashboardStyles.cardValueStyle.copyWith(
                          fontSize: 24,
                        ),
                      ),
                      Text('Items', style: DashboardStyles.pageSubtitleStyle),
                      Text(
                        _formatMoneyStatic(totalAmount),
                        style: DashboardStyles.smallGold,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: stats.length,
                itemBuilder: (_, index) {
                  final s = stats[index];
                  final pct = (s.items / totalItems) * 100;
                  final color = colors[index % colors.length];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: DashboardStyles.cardColor.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.42)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.supplier,
                            style: DashboardStyles.smallGold.copyWith(
                              color: DashboardStyles.textPrimary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          '${s.items} items',
                          style: DashboardStyles.pageSubtitleStyle,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatMoneyStatic(s.amount),
                          style: DashboardStyles.smallGold,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: DashboardStyles.smallGold.copyWith(
                            color: color,
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
      );
    }

    return SizedBox(
      height: 235,
      child: Column(
        children: [
          SizedBox(
            width: 95,
            height: 95,
            child: CustomPaint(
              painter: _DonutPainter(
                stats: stats,
                colors: colors,
                strokeWidth: 12,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalItems',
                      style: DashboardStyles.cardValueStyle.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Items',
                      style: DashboardStyles.pageSubtitleStyle.copyWith(
                        fontSize: 8,
                      ),
                    ),
                    Text(
                      _formatMoneyStatic(totalAmount),
                      style: DashboardStyles.smallGold.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: stats.length,
              itemBuilder: (_, index) {
                final s = stats[index];
                final pct = (s.items / totalItems) * 100;
                final color = colors[index % colors.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DashboardStyles.cardColor.withOpacity(0.78),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: color.withOpacity(0.42)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.supplier,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DashboardStyles.smallGold.copyWith(
                            color: DashboardStyles.textPrimary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      Text(
                        '${s.items}',
                        style: DashboardStyles.pageSubtitleStyle.copyWith(
                          fontSize: 8.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatMoneyStatic(s.amount),
                        style: DashboardStyles.smallGold.copyWith(
                          fontSize: 8.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: DashboardStyles.smallGold.copyWith(
                          color: color,
                          fontSize: 8.5,
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
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_SupplierStat> stats;
  final List<Color> colors;
  final double strokeWidth;

  _DonutPainter({
    required this.stats,
    required this.colors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = stats.fold<int>(0, (s, e) => s + e.items);
    if (total == 0) return;

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    ).deflate(strokeWidth / 1.4);

    double start = -math.pi / 2;

    for (int i = 0; i < stats.length; i++) {
      final sweep = (stats[i].items / total) * math.pi * 2;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

String _formatMoneyStatic(num value) {
  final parts = value.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '₱$whole.${parts[1]}';
}

String _formatMoneyShort(num value) {
  if (value >= 1000) return '₱${(value / 1000).toStringAsFixed(1)}k';

  final whole = value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');

  return '₱$whole';
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: DashboardStyles.pageSubtitleStyle.copyWith(fontSize: 10),
      ),
    );
  }
}
