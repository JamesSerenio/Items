import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/order_styles.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  final GlobalKey _cartIconKey = GlobalKey();
  final GlobalKey _ordersIconKey = GlobalKey();

  bool _isLoading = true;

  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _orders = [];
  final List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_loadMaterials(), _loadOrders()]);
    } catch (e) {
      _showSnack('Load failed: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMaterials() async {
    final data = await Supabase.instance.client
        .from('materials')
        .select(
          'id, supplier_name, description, unit, unit_value, price, quantity, total, location, created_at',
        )
        .order('created_at', ascending: false);

    if (!mounted) return;
    _materials = List<Map<String, dynamic>>.from(data);
  }

  Future<void> _loadOrders() async {
    final data = await Supabase.instance.client
        .from('purchase_orders')
        .select('id, po_no, description, total_amount, created_at')
        .order('created_at', ascending: false);

    if (!mounted) return;
    _orders = List<Map<String, dynamic>>.from(data);
  }

  List<Map<String, dynamic>> get _filteredMaterials {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _materials;

    return _materials.where((item) {
      return [
        item['supplier_name'],
        item['description'],
        item['unit'],
        item['location'],
      ].any((v) => (v?.toString().toLowerCase() ?? '').contains(q));
    }).toList();
  }

  num get _cartQty {
    num total = 0;
    for (final item in _cart) {
      total += _num(item['quantity']);
    }
    return total;
  }

  num get _cartTotal {
    num total = 0;
    for (final item in _cart) {
      total += _num(item['total_cost']);
    }
    return total;
  }

  String _text(dynamic value) => value?.toString() ?? '-';

  num _num(dynamic value) => num.tryParse(value?.toString() ?? '0') ?? 0;

  String _money(dynamic value) {
    final n = _num(value);
    return '₱${n.toStringAsFixed(2)}';
  }

  int _cartQtyForMaterial(dynamic materialId) {
    final index = _cart.indexWhere((e) => e['material_id'] == materialId);
    if (index < 0) return 0;
    return _num(_cart[index]['quantity']).toInt();
  }

  num _remainingStock(Map<String, dynamic> item) {
    final original = _num(item['quantity']);
    final used = _cartQtyForMaterial(item['id']);
    return original - used;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OrderStyles.panelCardColor,
      ),
    );
  }

  Offset? _centerOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final pos = box.localToGlobal(Offset.zero);
    return Offset(pos.dx + box.size.width / 2, pos.dy + box.size.height / 2);
  }

  void _flyToCart(GlobalKey fromKey) {
    final overlay = Overlay.of(context);
    final start = _centerOf(fromKey);
    final end = _centerOf(_cartIconKey);

    if (start == null || end == null) return;

    final entry = OverlayEntry(
      builder: (_) => _FlyingCart(start: start, end: end),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 900), entry.remove);
  }

  void _addToCart(Map<String, dynamic> item, GlobalKey buttonKey) {
    final remaining = _remainingStock(item);
    final price = _num(item['price']);

    if (remaining <= 0) {
      _showSnack('No more stock available');
      return;
    }

    final index = _cart.indexWhere((e) => e['material_id'] == item['id']);

    setState(() {
      if (index >= 0) {
        final qty = _num(_cart[index]['quantity']) + 1;
        _cart[index]['quantity'] = qty;
        _cart[index]['total_cost'] = qty * price;
      } else {
        _cart.add({
          'material_id': item['id'],
          'supplier_name': item['supplier_name'],
          'unit': item['unit'],
          'item_description': item['description'],
          'quantity': 1,
          'unit_cost': price,
          'total_cost': price,
          'available_qty': _num(item['quantity']),
          'location': item['location'],
        });
      }
    });

    _flyToCart(buttonKey);
  }

  void _increaseQty(int index) {
    final item = _cart[index];
    final qty = _num(item['quantity']);
    final stock = _num(item['available_qty']);
    final price = _num(item['unit_cost']);

    if (qty >= stock) {
      _showSnack('No more stock available');
      return;
    }

    setState(() {
      final newQty = qty + 1;
      _cart[index]['quantity'] = newQty;
      _cart[index]['total_cost'] = newQty * price;
    });
  }

  void _decreaseQty(int index) {
    final item = _cart[index];
    final qty = _num(item['quantity']);
    final price = _num(item['unit_cost']);

    setState(() {
      if (qty <= 1) {
        _cart.removeAt(index);
      } else {
        final newQty = qty - 1;
        _cart[index]['quantity'] = newQty;
        _cart[index]['total_cost'] = newQty * price;
      }
    });
  }

  void _removeCartItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  Future<void> _editCartQty(int index) async {
    final item = _cart[index];
    final controller = TextEditingController(text: _text(item['quantity']));

    final result = await showDialog<num>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: OrderStyles.panelCardColor,
        title: const Text(
          'Edit Quantity',
          style: TextStyle(color: OrderStyles.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: OrderStyles.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter quantity',
            hintStyle: const TextStyle(color: OrderStyles.textSecondary),
            filled: true,
            fillColor: OrderStyles.inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final qty = num.tryParse(controller.text.trim());
              Navigator.pop(context, qty);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final stock = _num(item['available_qty']);
    final price = _num(item['unit_cost']);

    if (result <= 0) {
      _showSnack('Quantity must be greater than 0');
      return;
    }

    if (result > stock) {
      _showSnack('Only ${stock.toString()} stock available');
      return;
    }

    setState(() {
      _cart[index]['quantity'] = result;
      _cart[index]['total_cost'] = result * price;
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      _showSnack('Cart is empty');
      return;
    }

    final description = await _openDescriptionDialog();
    if (description == null) return;

    try {
      final items = _cart.map((item) {
        return {
          'material_id': item['material_id'],
          'unit': item['unit'],
          'item_description': item['item_description'],
          'quantity': item['quantity'],
          'unit_cost': item['unit_cost'],
          'location': item['location'],
        };
      }).toList();

      await Supabase.instance.client.rpc(
        'checkout_purchase_order',
        params: {'p_description': description, 'p_items': items},
      );

      if (!mounted) return;

      setState(() => _cart.clear());
      await _loadAll();

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Purchase order created');
    } catch (e) {
      _showSnack('Checkout failed: $e');
    }
  }

  Future<String?> _openDescriptionDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(22),
            decoration: OrderStyles.popupDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: OrderStyles.plutoGold),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Write Order Description',
                        style: OrderStyles.popupTitleStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  style: const TextStyle(color: OrderStyles.textPrimary),
                  decoration: OrderStyles.descriptionInputDecoration,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OrderStyles.cancelButtonStyle,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final text = controller.text.trim();
                          Navigator.pop(
                            context,
                            text.isEmpty ? 'Purchase Order' : text,
                          );
                        },
                        style: OrderStyles.checkoutButtonStyle,
                        child: const Text(
                          'Save Order',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCartModal() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.70),
      builder: (_) {
        final isMobile = MediaQuery.of(context).size.width < 768;

        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            void refreshModal() {
              setState(() {});
              setModalState(() {});
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(isMobile ? 12 : 22),
              child: Container(
                width: isMobile ? double.infinity : 680,
                height: MediaQuery.of(context).size.height * 0.78,
                decoration: OrderStyles.cartPanelDecoration,
                padding: EdgeInsets.all(isMobile ? 14 : 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: OrderStyles.statIconDecoration,
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: OrderStyles.plutoGold,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Current Order',
                            style: OrderStyles.cartTitleStyle,
                          ),
                        ),
                        _MiniPill(text: '${_cart.length} items'),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: OrderStyles.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) {
                                final item = _cart[index];

                                return Container(
                                  height: isMobile ? 54 : 62,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 12,
                                    vertical: isMobile ? 6 : 9,
                                  ),
                                  decoration: OrderStyles.cartItemDecoration,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: isMobile ? 30 : 38,
                                        height: isMobile ? 30 : 38,
                                        decoration:
                                            OrderStyles.statIconDecoration,
                                        child: Icon(
                                          Icons.inventory_2_outlined,
                                          color: OrderStyles.plutoGold,
                                          size: isMobile ? 15 : 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 26,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _text(
                                                      item['item_description'],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: OrderStyles
                                                        .cartItemNameStyle
                                                        .copyWith(
                                                          fontSize: isMobile
                                                              ? 10
                                                              : 13,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${_text(item['supplier_name'])} • ${_text(item['unit'])}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: OrderStyles
                                                        .cartItemMetaStyle
                                                        .copyWith(
                                                          fontSize: isMobile
                                                              ? 7.5
                                                              : 10,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Expanded(
                                              flex: 15,
                                              child: Text(
                                                _money(item['total_cost']),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.right,
                                                style: OrderStyles
                                                    .orderTotalStyle
                                                    .copyWith(
                                                      fontSize: isMobile
                                                          ? 10
                                                          : 13,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 6),

                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () async {
                                          await _editCartQty(index);
                                          refreshModal();
                                        },
                                        child: Container(
                                          width: isMobile ? 34 : 44,
                                          height: isMobile ? 26 : 30,
                                          alignment: Alignment.center,
                                          decoration:
                                              OrderStyles.unitPillDecoration,
                                          child: Text(
                                            _text(item['quantity']),
                                            style: OrderStyles.qtyTextStyle
                                                .copyWith(
                                                  fontSize: isMobile ? 12 : 14,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 5),

                                      InkWell(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        onTap: () {
                                          _removeCartItem(index);
                                          refreshModal();
                                        },
                                        child: Container(
                                          width: isMobile ? 24 : 28,
                                          height: isMobile ? 24 : 28,
                                          decoration: BoxDecoration(
                                            color: OrderStyles.dangerColor
                                                .withOpacity(0.10),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: OrderStyles.dangerColor
                                                  .withOpacity(0.55),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: OrderStyles.dangerColor,
                                            size: isMobile ? 13 : 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: OrderStyles.totalBoxDecoration,
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total Amount',
                              style: OrderStyles.totalLabelStyle,
                            ),
                          ),
                          Text(
                            _money(_cartTotal),
                            style: OrderStyles.totalValueStyle.copyWith(
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _voidOrder(Map<String, dynamic> order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: OrderStyles.panelCardColor,
        title: const Text(
          'Void Order?',
          style: TextStyle(color: OrderStyles.textPrimary),
        ),
        content: Text(
          'Void ${_text(order['description'])}? Stocks will be returned.',
          style: const TextStyle(color: OrderStyles.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Void',
              style: TextStyle(color: OrderStyles.dangerColor),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.rpc(
        'void_purchase_order',
        params: {'p_order_id': order['id']},
      );

      await _loadAll();

      if (!mounted) return;

      Navigator.pop(context);
      _showSnack('Order voided and stocks returned');
    } catch (e) {
      _showSnack('Void failed: $e');
    }
  }

  Future<void> _openOrdersModal() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.62),
      builder: (_) {
        final isMobile = MediaQuery.of(context).size.width < 768;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isMobile ? 12 : 22),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 620,
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            decoration: OrderStyles.cartPanelDecoration,
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: OrderStyles.plutoGold,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Orders', style: OrderStyles.cartTitleStyle),
                    ),
                    _MiniPill(text: '${_orders.length}'),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: OrderStyles.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _orders.isEmpty
                      ? const Center(
                          child: Text(
                            'No orders yet',
                            style: OrderStyles.emptyStyle,
                          ),
                        )
                      : ListView.separated(
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final order = _orders[index];

                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _openPurchaseOrder(order),
                              child: Container(
                                padding: const EdgeInsets.all(13),
                                decoration: OrderStyles.orderItemDecoration,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      color: OrderStyles.plutoGold,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _text(order['description']),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                OrderStyles.cartItemNameStyle,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _text(order['po_no']),
                                            style:
                                                OrderStyles.cartItemMetaStyle,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _money(order['total_amount']),
                                          style: OrderStyles.orderTotalStyle,
                                        ),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          onTap: () => _voidOrder(order),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: OrderStyles.dangerColor
                                                  .withOpacity(0.13),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: OrderStyles.dangerColor
                                                    .withOpacity(0.55),
                                              ),
                                            ),
                                            child: const Text(
                                              'Void',
                                              style: TextStyle(
                                                color: OrderStyles.dangerColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  Future<void> _openPurchaseOrder(Map<String, dynamic> order) async {
    final items = await Supabase.instance.client
        .from('purchase_order_items')
        .select(
          'stock_no, unit, item_description, quantity, unit_cost, total_cost, location',
        )
        .eq('purchase_order_id', order['id'])
        .order('stock_no', ascending: true);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) {
        final screen = MediaQuery.of(context).size;
        final paperWidth = screen.width < 900 ? screen.width * 0.92 : 794.0;
        final paperHeight = paperWidth * 1.414;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: paperWidth,
                height: paperHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: paperWidth < 700 ? 22 : 42,
                  vertical: paperWidth < 700 ? 22 : 34,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 42),
                        const Expanded(
                          child: Text(
                            'PURCHASE ORDER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Description: ${_text(order['description'])}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            'Date: ${DateTime.tryParse(_text(order['created_at']))?.toLocal().toString().split('.').first ?? '-'}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _PurchaseTable(
                      items: List<Map<String, dynamic>>.from(items),
                      text: _text,
                      money: _money,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.black, width: 2),
                          bottom: BorderSide(color: Colors.black54),
                          left: BorderSide(color: Colors.black54),
                          right: BorderSide(color: Colors.black54),
                        ),
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
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopIcons(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Orders',
            style: isMobile
                ? OrderStyles.pageTitleMobileStyle
                : OrderStyles.pageTitleStyle,
          ),
        ),
        _TopIconButton(
          key: _cartIconKey,
          icon: Icons.shopping_bag_outlined,
          badge: _cart.length.toString(),
          onTap: _openCartModal,
        ),
        const SizedBox(width: 10),
        _TopIconButton(
          key: _ordersIconKey,
          icon: Icons.receipt_long_outlined,
          badge: _orders.length.toString(),
          onTap: _openOrdersModal,
        ),
      ],
    );
  }

  Widget _buildStats(bool isMobile) {
    return Row(
      children: [
        _StatCard(
          label: 'Products',
          value: _filteredMaterials.length.toString(),
          icon: Icons.inventory_2_outlined,
          isMobile: isMobile,
        ),
        SizedBox(width: isMobile ? 8 : 14),
        _StatCard(
          label: 'Cart',
          value: _cartQty.toString(),
          icon: Icons.shopping_cart_outlined,
          isMobile: isMobile,
        ),
        SizedBox(width: isMobile ? 8 : 14),
        _StatCard(
          label: isMobile ? 'Total' : 'Cart Total',
          value: _money(_cartTotal),
          icon: Icons.payments_outlined,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildSearch(bool isMobile) {
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
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: isMobile ? 48 : 58,
          width: isMobile ? 52 : 58,
          child: IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded),
            style: OrderStyles.refreshButtonStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildProducts(bool isMobile) {
    final items = _filteredMaterials;

    if (items.isEmpty) {
      return const Center(
        child: Text('No products found', style: OrderStyles.emptyStyle),
      );
    }

    if (isMobile) {
      return Container(
        width: double.infinity,
        decoration: OrderStyles.tableOuterDecoration.copyWith(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              Container(
                height: 34,
                color: OrderStyles.tableHeaderColor,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: const Row(
                  children: [
                    Expanded(flex: 26, child: _MobileHeaderText('Product')),
                    Expanded(flex: 22, child: _MobileHeaderText('Supplier')),
                    Expanded(flex: 16, child: _MobileHeaderText('Price')),
                    Expanded(flex: 12, child: _MobileHeaderText('Qty')),
                    SizedBox(width: 32, child: _MobileHeaderText('Add')),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 0.45,
                    color: OrderStyles.borderColor.withOpacity(0.55),
                  ),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final key = GlobalKey();
                    final stock = _remainingStock(item);

                    return Container(
                      height: 62,
                      color: OrderStyles.tableRowColor,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 26,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MobileCellText(_text(item['description'])),
                                const SizedBox(height: 2),
                                Text(
                                  '${_text(item['unit'])} • UV ${_text(item['unit_value'])}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: OrderStyles.pageSubtitleStyle.copyWith(
                                    fontSize: 6.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 22,
                            child: _MobileCellText(
                              _text(item['supplier_name']),
                            ),
                          ),
                          Expanded(
                            flex: 16,
                            child: _MiniMoneyText(_money(item['price'])),
                          ),
                          Expanded(
                            flex: 12,
                            child: _MiniText(
                              stock <= 0 ? 'Out' : stock.toString(),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            key: key,
                            child: _TinyActionButton(
                              icon: Icons.add_shopping_cart_rounded,
                              color: stock <= 0
                                  ? Colors.grey
                                  : OrderStyles.primaryColor,
                              onTap: stock <= 0
                                  ? () {}
                                  : () => _addToCart(item, key),
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
    }

    return Container(
      width: double.infinity,
      decoration: OrderStyles.tableOuterDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              height: 58,
              color: OrderStyles.tableHeaderColor,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Row(
                children: [
                  Expanded(flex: 28, child: _HeaderText('Product')),
                  Expanded(flex: 18, child: _HeaderText('Supplier')),
                  Expanded(flex: 12, child: _HeaderText('Unit')),
                  Expanded(flex: 14, child: _HeaderText('Price')),
                  Expanded(flex: 12, child: _HeaderText('Stock')),
                  Expanded(flex: 18, child: _HeaderText('Location')),
                  Expanded(flex: 18, child: _HeaderText('Order')),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.6,
                  color: OrderStyles.borderColor.withOpacity(0.45),
                ),
                itemBuilder: (_, index) {
                  final item = items[index];
                  final key = GlobalKey();
                  final stock = _remainingStock(item);

                  return Container(
                    height: 72,
                    color: OrderStyles.tableRowColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 28,
                          child: _CellText(_text(item['description'])),
                        ),
                        Expanded(
                          flex: 18,
                          child: _CellText(_text(item['supplier_name'])),
                        ),
                        Expanded(
                          flex: 12,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _UnitPill(_text(item['unit'])),
                          ),
                        ),
                        Expanded(
                          flex: 14,
                          child: _CellText(
                            _money(item['price']),
                            highlight: true,
                          ),
                        ),
                        Expanded(
                          flex: 12,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _StockBadge(
                              text: stock <= 0 ? 'Out' : stock.toString(),
                              isOut: stock <= 0,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 18,
                          child: _CellText(_text(item['location'])),
                        ),
                        Expanded(
                          flex: 18,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              key: key,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: stock <= 0
                                    ? null
                                    : () => _addToCart(item, key),
                                style: OrderStyles.addCartButtonStyle,
                                icon: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                  size: 17,
                                ),
                                label: const Text('Add to Cart'),
                              ),
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
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

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
            _buildTopIcons(isMobile),
            const SizedBox(height: 5),
            Text(
              'Add products to cart and generate purchase orders.',
              style: OrderStyles.pageSubtitleStyle.copyWith(
                fontSize: isMobile ? 12.5 : 14,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 20),
            _buildStats(isMobile),
            SizedBox(height: isMobile ? 12 : 18),
            _buildSearch(isMobile),
            SizedBox(height: isMobile ? 12 : 18),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProducts(isMobile),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String Function(dynamic value) text;
  final String Function(dynamic value) money;

  const _PurchaseTable({
    required this.items,
    required this.text,
    required this.money,
  });

  TableRow _header() {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w800,
      fontSize: 12,
    );

    return const TableRow(
      decoration: BoxDecoration(color: Color(0xFFF1F1F1)),
      children: [
        _PoCell('STOCK NO.', style: style, center: true),
        _PoCell('UNIT', style: style, center: true),
        _PoCell('ITEM DESCRIPTION', style: style),
        _PoCell('LOCATION', style: style),
        _PoCell('QTY', style: style, center: true),
        _PoCell('UNIT COST', style: style, right: true),
        _PoCell('TOTAL COST', style: style, right: true),
      ],
    );
  }

  TableRow _row(Map<String, dynamic> i) {
    const style = TextStyle(color: Colors.black87, fontSize: 12.5);

    return TableRow(
      children: [
        _PoCell(text(i['stock_no']), style: style, center: true),
        _PoCell(text(i['unit']), style: style, center: true),
        _PoCell(text(i['item_description']), style: style),
        _PoCell(text(i['location']), style: style),
        _PoCell(text(i['quantity']), style: style, center: true),
        _PoCell(money(i['unit_cost']), style: style, right: true),
        _PoCell(money(i['total_cost']), style: style, right: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.black54, width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(0.9),
        1: FlexColumnWidth(0.8),
        2: FlexColumnWidth(2.1),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(0.7),
        5: FlexColumnWidth(1.2),
        6: FlexColumnWidth(1.3),
      },
      children: [_header(), ...items.map(_row)],
    );
  }
}

class _PoCell extends StatelessWidget {
  final String value;
  final TextStyle style;
  final bool center;
  final bool right;

  const _PoCell(
    this.value, {
    required this.style,
    this.center = false,
    this.right = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: right
          ? Alignment.centerRight
          : center
          ? Alignment.center
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: right
            ? TextAlign.right
            : center
            ? TextAlign.center
            : TextAlign.left,
        style: style,
      ),
    );
  }
}

class _FlyingCart extends StatefulWidget {
  final Offset start;
  final Offset end;

  const _FlyingCart({required this.start, required this.end});

  @override
  State<_FlyingCart> createState() => _FlyingCartState();
}

class _FlyingCartState extends State<_FlyingCart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _bezier(double t) {
    final p0 = widget.start;
    final p2 = widget.end;
    final p1 = Offset((p0.dx + p2.dx) / 2, p0.dy - 180);

    final x =
        (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y =
        (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, __) {
        final t = _curve.value;
        final pos = _bezier(t);

        return Positioned(
          left: pos.dx - 18,
          top: pos.dy - 18,
          child: Transform.scale(
            scale: 1.15 - (t * 0.35),
            child: Opacity(
              opacity: 1 - (t * 0.15),
              child: Container(
                width: 38,
                height: 38,
                decoration: OrderStyles.flyIconDecoration,
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String badge;
  final VoidCallback onTap;

  const _TopIconButton({
    super.key,
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 54,
            height: 54,
            decoration: OrderStyles.topIconDecoration,
            child: Icon(icon, color: OrderStyles.plutoGold),
          ),
        ),
        Positioned(
          right: -4,
          top: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: OrderStyles.badgeDecoration,
            child: Text(badge, style: OrderStyles.badgeTextStyle),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isMobile;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: isMobile ? 68 : 92,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 7 : 18,
          vertical: isMobile ? 8 : 16,
        ),
        decoration: OrderStyles.statCardDecoration,
        child: Row(
          children: [
            Container(
              width: isMobile ? 28 : 48,
              height: isMobile ? 28 : 48,
              decoration: OrderStyles.statIconDecoration,
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
                    overflow: TextOverflow.ellipsis,
                    style: OrderStyles.statLabelStyle.copyWith(
                      fontSize: isMobile ? 10.5 : 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
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
  final bool highlight;

  const _CellText(this.text, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: highlight
          ? OrderStyles.tableHighlightTextStyle
          : OrderStyles.tableCellTextStyle,
    );
  }
}

class _MobileHeaderText extends StatelessWidget {
  final String text;

  const _MobileHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: OrderStyles.tableHeaderTextStyle.copyWith(fontSize: 7.2),
    );
  }
}

class _MobileCellText extends StatelessWidget {
  final String text;

  const _MobileCellText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: OrderStyles.tableCellTextStyle.copyWith(
        fontSize: 8.1,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _MiniText extends StatelessWidget {
  final String text;

  const _MiniText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: OrderStyles.tableCellTextStyle.copyWith(
        fontSize: 7.6,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _MiniMoneyText extends StatelessWidget {
  final String text;

  const _MiniMoneyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: OrderStyles.tableHighlightTextStyle.copyWith(
        fontSize: 7.2,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TinyActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withOpacity(0.45), width: 0.8),
        ),
        child: Icon(icon, color: color, size: 13),
      ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
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
        width: 24,
        height: 24,
        decoration: OrderStyles.qtyButtonDecoration,
        child: Icon(icon, size: 14, color: OrderStyles.plutoGold),
      ),
    );
  }
}
