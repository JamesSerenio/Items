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
          .select('id, po_no, description, total_amount, created_at')
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

  String _money(num value) => '₱${value.toStringAsFixed(2)}';

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

  DateTime _startDate() {
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

  int get totalSuppliers {
    return filteredItems
        .map(_supplier)
        .where((s) => s.isNotEmpty)
        .toSet()
        .length;
  }

  int get totalMaterials {
    return filteredItems.fold<int>(
      0,
      (sum, i) => sum + _num(i['quantity']).toInt(),
    );
  }

  num get totalAmount {
    return filteredItems.fold<num>(0, (sum, i) => sum + _num(i['total_cost']));
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
    list.sort((a, b) => b.items.compareTo(a.items));
    return list;
  }

  String get filterLabel {
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
                        onChanged: (v) {
                          setState(() => selectedFilter = v);
                        },
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

                      _Panel(
                        title: 'Purchase Amount Trend',
                        subtitle: 'Total amount ordered for $filterLabel.',
                        child: SizedBox(
                          height: isMobile ? 125 : 310,
                          child: _LineChart(points: lineData),
                        ),
                      ),

                      SizedBox(height: isMobile ? 10 : 18),

                      _Panel(
                        title: 'Supplier Item Orders',
                        subtitle: 'Number of items ordered per supplier.',
                        child: SizedBox(
                          height: isMobile ? 125 : 310,
                          child: _BarChart(stats: supplierStats),
                        ),
                      ),

                      SizedBox(height: isMobile ? 10 : 18),

                      _Panel(
                        title: 'Supplier Share',
                        subtitle: 'Percentage and total amount per supplier.',
                        child: _DonutSection(stats: supplierStats),
                      ),
                    ],
                  ),
                ),
              ),
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
  final ValueChanged<DashboardFilter> onChanged;

  const _Header({
    required this.isMobile,
    required this.selected,
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
        ),
      ],
    );
  }
}

class _FilterPills extends StatelessWidget {
  final DashboardFilter selected;
  final ValueChanged<DashboardFilter> onChanged;
  final bool isMobile;

  const _FilterPills({
    required this.selected,
    required this.onChanged,
    required this.isMobile,
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
        final active = selected == e.key;

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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 20),
      decoration: BoxDecoration(
        color: DashboardStyles.cardColor,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
        border: Border.all(color: DashboardStyles.plutoGold.withOpacity(0.68)),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 34 : 52,
            height: isMobile ? 34 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.13),
              border: Border.all(color: color.withOpacity(0.65)),
            ),
            child: Icon(icon, color: color, size: isMobile ? 17 : 24),
          ),
          SizedBox(width: isMobile ? 10 : 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DashboardStyles.cardTitleStyle),
                SizedBox(height: isMobile ? 3 : 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: DashboardStyles.cardValueStyle.copyWith(
                      fontSize: isMobile ? 18 : 24,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardStyles.pageSubtitleStyle.copyWith(
                    fontSize: isMobile ? 9.5 : 12,
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
    if (stats.isEmpty) {
      return const _EmptyChart(message: 'No supplier orders yet.');
    }

    final maxItems = stats.map((e) => e.items).fold<int>(1, math.max);

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: stats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final s = stats[index];
        final width = s.items / maxItems;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.supplier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardStyles.smallGold.copyWith(fontSize: 9),
                  ),
                ),
                Text(
                  '${s.items} • ${_formatMoneyStatic(s.amount)}',
                  style: DashboardStyles.pageSubtitleStyle.copyWith(
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: DashboardStyles.plutoGold.withOpacity(0.12),
                  ),
                  FractionallySizedBox(
                    widthFactor: width,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DashboardStyles.megaGreen,
                            DashboardStyles.plutoGold,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
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
  return '₱${value.toStringAsFixed(2)}';
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
