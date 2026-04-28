import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/order_styles.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _materials = [];
  final List<Map<String, dynamic>> _cart = [];
  final List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);

    try {
      final data = await Supabase.instance.client
          .from('materials')
          .select(
            'id, supplier_name, description, unit, unit_value, price, quantity, total, location, created_at',
          )
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _materials = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Load failed: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredMaterials {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _materials;

    return _materials.where((item) {
      return [
        item['supplier_name'],
        item['description'],
        item['unit'],
        item['unit_value'],
        item['location'],
      ].any((v) => (v?.toString().toLowerCase() ?? '').contains(query));
    }).toList();
  }

  num get _cartTotal {
    num total = 0;
    for (final item in _cart) {
      total += num.tryParse(item['line_total']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  num get _cartQty {
    num total = 0;
    for (final item in _cart) {
      total += num.tryParse(item['order_qty']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  num get _ordersTotal {
    num total = 0;
    for (final order in _orders) {
      total += num.tryParse(order['total']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  String _text(dynamic value) => value?.toString() ?? '-';

  String _money(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '0') ?? 0;
    return '₱${number.toStringAsFixed(2)}';
  }

  num _num(dynamic value) {
    return num.tryParse(value?.toString() ?? '0') ?? 0;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OrderStyles.panelCardColor,
      ),
    );
  }

  void _addToCart(Map<String, dynamic> item) {
    final availableQty = _num(item['quantity']);
    final price = _num(item['price']);

    if (availableQty <= 0) {
      _showSnack('This item is out of stock');
      return;
    }

    final index = _cart.indexWhere(
      (cartItem) => cartItem['id'].toString() == item['id'].toString(),
    );

    setState(() {
      if (index >= 0) {
        final currentQty = _num(_cart[index]['order_qty']);
        if (currentQty >= availableQty) {
          _showSnack('No more stock available');
          return;
        }

        final newQty = currentQty + 1;
        _cart[index]['order_qty'] = newQty;
        _cart[index]['line_total'] = newQty * price;
      } else {
        _cart.add({
          'id': item['id'],
          'description': item['description'],
          'supplier_name': item['supplier_name'],
          'unit': item['unit'],
          'unit_value': item['unit_value'],
          'price': price,
          'available_qty': availableQty,
          'order_qty': 1,
          'line_total': price,
        });
      }
    });

    _showSnack('${_text(item['description'])} added to cart');
  }

  void _increaseCartQty(int index) {
    final item = _cart[index];
    final currentQty = _num(item['order_qty']);
    final availableQty = _num(item['available_qty']);
    final price = _num(item['price']);

    if (currentQty >= availableQty) {
      _showSnack('No more stock available');
      return;
    }

    setState(() {
      final newQty = currentQty + 1;
      _cart[index]['order_qty'] = newQty;
      _cart[index]['line_total'] = newQty * price;
    });
  }

  void _decreaseCartQty(int index) {
    final item = _cart[index];
    final currentQty = _num(item['order_qty']);
    final price = _num(item['price']);

    setState(() {
      if (currentQty <= 1) {
        _cart.removeAt(index);
      } else {
        final newQty = currentQty - 1;
        _cart[index]['order_qty'] = newQty;
        _cart[index]['line_total'] = newQty * price;
      }
    });
  }

  void _checkout() {
    if (_cart.isEmpty) {
      _showSnack('Cart is empty');
      return;
    }

    final orderNo = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _orders.insert(0, {
        'order_no': orderNo,
        'items': List<Map<String, dynamic>>.from(_cart),
        'item_count': _cart.length,
        'qty': _cartQty,
        'total': _cartTotal,
        'created_at': DateTime.now(),
      });

      _cart.clear();
    });

    _showSnack('Order created successfully');
  }

  Widget _compactStatCard({
    required String label,
    required String value,
    required IconData icon,
    required bool isMobile,
  }) {
    return Expanded(
      child: Container(
        height: isMobile ? 68 : 92,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 7 : 18,
          vertical: isMobile ? 8 : 16,
        ),
        decoration: OrderStyles.statCardDecoration.copyWith(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 22),
        ),
        child: Row(
          children: [
            Container(
              width: isMobile ? 28 : 48,
              height: isMobile ? 28 : 48,
              decoration: OrderStyles.statIconDecoration.copyWith(
                borderRadius: BorderRadius.circular(isMobile ? 11 : 15),
              ),
              child: Icon(
                icon,
                color: OrderStyles.primaryColor,
                size: isMobile ? 17 : 22,
              ),
            ),
            SizedBox(width: isMobile ? 6 : 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OrderStyles.statLabelStyle.copyWith(
                      fontSize: isMobile ? 10.5 : 13,
                    ),
                  ),
                  SizedBox(height: isMobile ? 2 : 5),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OrderStyles.statValueStyle.copyWith(
                      fontSize: isMobile ? 12.5 : 18,
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

  Widget _buildStats(bool isMobile) {
    return Row(
      children: [
        _compactStatCard(
          label: 'Products',
          value: _filteredMaterials.length.toString(),
          icon: Icons.inventory_2_outlined,
          isMobile: isMobile,
        ),
        SizedBox(width: isMobile ? 8 : 14),
        _compactStatCard(
          label: 'Cart',
          value: _cartQty.toString(),
          icon: Icons.shopping_cart_outlined,
          isMobile: isMobile,
        ),
        SizedBox(width: isMobile ? 8 : 14),
        _compactStatCard(
          label: isMobile ? 'Total' : 'Cart Total',
          value: _money(_cartTotal),
          icon: Icons.payments_outlined,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildSearchAndRefresh(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: isMobile ? 48 : 58,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: OrderStyles.textPrimary),
              decoration: OrderStyles.searchDecoration.copyWith(
                hintText: isMobile
                    ? 'Search item...'
                    : 'Search product, supplier, unit, or location...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 18,
                  vertical: isMobile ? 12 : 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: isMobile ? 48 : 58,
          width: isMobile ? 52 : 58,
          child: IconButton(
            onPressed: _loadMaterials,
            icon: const Icon(Icons.refresh_rounded),
            style: OrderStyles.refreshButtonStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildProductTable(bool isMobile) {
    final items = _filteredMaterials;

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No products found', style: OrderStyles.emptyStyle),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double minTableWidth = isMobile ? 760 : constraints.maxWidth;

        return Container(
          width: double.infinity,
          decoration: OrderStyles.tableOuterDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              primary: false,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minTableWidth,
                child: SingleChildScrollView(
                  primary: false,
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowHeight: isMobile ? 48 : 58,
                    dataRowMinHeight: isMobile ? 54 : 62,
                    dataRowMaxHeight: isMobile ? 62 : 70,
                    horizontalMargin: isMobile ? 10 : 22,
                    columnSpacing: isMobile ? 14 : 26,
                    dividerThickness: 0.6,
                    headingRowColor: WidgetStateProperty.all(
                      OrderStyles.tableHeaderColor,
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith(
                      (states) => OrderStyles.tableRowColor,
                    ),
                    columns: const [
                      DataColumn(label: _HeaderText('Product')),
                      DataColumn(label: _HeaderText('Supplier')),
                      DataColumn(label: _HeaderText('Unit')),
                      DataColumn(label: _HeaderText('Price')),
                      DataColumn(label: _HeaderText('Stock')),
                      DataColumn(label: _HeaderText('Location')),
                      DataColumn(label: _HeaderText('Order')),
                    ],
                    rows: items.map((item) {
                      final qty = _num(item['quantity']);

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: isMobile ? 120 : 180,
                              child: _CellText(_text(item['description'])),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: isMobile ? 95 : 135,
                              child: _CellText(_text(item['supplier_name'])),
                            ),
                          ),
                          DataCell(_UnitPill(_text(item['unit']))),
                          DataCell(
                            _CellText(_money(item['price']), isHighlight: true),
                          ),
                          DataCell(
                            _StockBadge(
                              text: qty <= 0 ? 'Out' : qty.toString(),
                              isOut: qty <= 0,
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: isMobile ? 90 : 130,
                              child: _CellText(_text(item['location'])),
                            ),
                          ),
                          DataCell(
                            ElevatedButton.icon(
                              onPressed: qty <= 0
                                  ? null
                                  : () => _addToCart(item),
                              style: OrderStyles.addCartButtonStyle,
                              icon: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 17,
                              ),
                              label: Text(isMobile ? 'Add' : 'Add to Cart'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartPanel(bool isMobile) {
    return Container(
      decoration: OrderStyles.cartPanelDecoration,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: OrderStyles.plutoGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current Order',
                  style: OrderStyles.cartTitleStyle.copyWith(
                    fontSize: isMobile ? 16 : 18,
                  ),
                ),
              ),
              _MiniPill(text: '${_cart.length} items'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'No item added yet',
                      style: OrderStyles.emptyStyle,
                    ),
                  )
                : ListView.separated(
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _cart[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: OrderStyles.cartItemDecoration,
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: OrderStyles.cartIconDecoration,
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: OrderStyles.plutoGold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _text(item['description']),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: OrderStyles.cartItemNameStyle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_text(item['unit'])} • ${_money(item['price'])}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: OrderStyles.cartItemMetaStyle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                _QtyButton(
                                  icon: Icons.remove_rounded,
                                  onTap: () => _decreaseCartQty(index),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    _text(item['order_qty']),
                                    style: OrderStyles.qtyTextStyle,
                                  ),
                                ),
                                _QtyButton(
                                  icon: Icons.add_rounded,
                                  onTap: () => _increaseCartQty(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: OrderStyles.totalBoxDecoration,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Amount',
                    style: OrderStyles.totalLabelStyle,
                  ),
                ),
                Text(_money(_cartTotal), style: OrderStyles.totalValueStyle),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _checkout,
              style: OrderStyles.checkoutButtonStyle,
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text(
                'Checkout Order',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersPanel(bool isMobile) {
    return Container(
      decoration: OrderStyles.cartPanelDecoration,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt_rounded, color: OrderStyles.plutoGold),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Orders', style: OrderStyles.cartTitleStyle),
              ),
              _MiniPill(text: _money(_ordersTotal)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _orders.isEmpty
                ? const Center(
                    child: Text('No orders yet', style: OrderStyles.emptyStyle),
                  )
                : ListView.separated(
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = _orders[index];

                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: OrderStyles.orderItemDecoration,
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: OrderStyles.cartIconDecoration,
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: OrderStyles.plutoGold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _text(order['order_no']),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: OrderStyles.cartItemNameStyle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_text(order['item_count'])} item(s) • Qty ${_text(order['qty'])}',
                                    style: OrderStyles.cartItemMetaStyle,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _money(order['total']),
                              style: OrderStyles.orderTotalStyle,
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

  Widget _buildDesktopLayout(bool isMobile) {
    return Row(
      children: [
        Expanded(flex: 7, child: _buildProductTable(isMobile)),
        const SizedBox(width: 16),
        SizedBox(
          width: 360,
          child: Column(
            children: [
              Expanded(flex: 6, child: _buildCartPanel(isMobile)),
              const SizedBox(height: 16),
              Expanded(flex: 4, child: _buildOrdersPanel(isMobile)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isMobile) {
    return Column(
      children: [
        SizedBox(height: 360, child: _buildProductTable(isMobile)),
        const SizedBox(height: 12),
        SizedBox(height: 310, child: _buildCartPanel(isMobile)),
        const SizedBox(height: 12),
        SizedBox(height: 240, child: _buildOrdersPanel(isMobile)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      decoration: OrderStyles.pageBackground,
      child: Container(
        decoration: isMobile
            ? OrderStyles.mobilePanelDecoration
            : OrderStyles.panelDecoration,
        padding: EdgeInsets.all(isMobile ? 12 : 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orders',
              style: isMobile
                  ? OrderStyles.pageTitleMobileStyle.copyWith(fontSize: 22)
                  : OrderStyles.pageTitleStyle,
            ),
            const SizedBox(height: 5),
            Text(
              'Add products to cart and view created orders.',
              style: OrderStyles.pageSubtitleStyle.copyWith(
                fontSize: isMobile ? 12.5 : 14,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 20),
            _buildStats(isMobile),
            SizedBox(height: isMobile ? 12 : 18),
            _buildSearchAndRefresh(isMobile),
            SizedBox(height: isMobile ? 12 : 18),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : isMobile
                  ? SingleChildScrollView(child: _buildMobileLayout(isMobile))
                  : _buildDesktopLayout(isMobile),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: OrderStyles.tableHeaderTextStyle);
  }
}

class _CellText extends StatelessWidget {
  final String text;
  final bool isHighlight;

  const _CellText(this.text, {this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: isHighlight
          ? OrderStyles.tableHighlightTextStyle
          : OrderStyles.tableCellTextStyle,
    );
  }
}

class _UnitPill extends StatelessWidget {
  final String text;

  const _UnitPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: OrderStyles.unitPillDecoration,
      child: Text(text, style: OrderStyles.unitPillTextStyle),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String text;
  final bool isOut;

  const _StockBadge({required this.text, required this.isOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: isOut
          ? OrderStyles.outStockDecoration
          : OrderStyles.stockBadgeDecoration,
      child: Text(
        text,
        style: isOut
            ? OrderStyles.outStockTextStyle
            : OrderStyles.stockBadgeTextStyle,
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;

  const _MiniPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: OrderStyles.unitPillDecoration,
      child: Text(text, style: OrderStyles.unitPillTextStyle),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: OrderStyles.qtyButtonDecoration,
        child: Icon(icon, size: 18, color: OrderStyles.plutoGold),
      ),
    );
  }
}
