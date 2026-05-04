import 'package:flutter/material.dart';

import '../styles/order_styles.dart';

class CurrentOrderModal extends StatelessWidget {
  final List<Map<String, dynamic>> cart;
  final String Function(dynamic value) text;
  final String Function(dynamic value) money;
  final num cartTotal;
  final Future<void> Function(int index) onEditQty;
  final void Function(int index) onRemove;
  final Future<void> Function() onCheckout;

  const CurrentOrderModal({
    super.key,
    required this.cart,
    required this.text,
    required this.money,
    required this.cartTotal,
    required this.onEditQty,
    required this.onRemove,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return StatefulBuilder(
      builder: (context, setModalState) {
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
                    _MiniPill(text: '${cart.length} items'),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: OrderStyles.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: cart.isEmpty
                      ? const Center(
                          child: Text(
                            'No item added yet',
                            style: OrderStyles.emptyStyle,
                          ),
                        )
                      : ListView.separated(
                          itemCount: cart.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final item = cart[index];

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
                                    decoration: OrderStyles.statIconDecoration,
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
                                                text(item['item_description']),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                                '${text(item['supplier_name'])}${(item['brand']?.toString().trim() ?? '').isNotEmpty ? ' • Brand: ${item['brand']}' : ''} • ${text(item['unit'])}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                            money(item['total_cost']),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                            style: OrderStyles.orderTotalStyle
                                                .copyWith(
                                                  fontSize: isMobile ? 10 : 13,
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
                                      await onEditQty(index);
                                      setModalState(() {});
                                    },
                                    child: Container(
                                      width: isMobile ? 34 : 44,
                                      height: isMobile ? 26 : 30,
                                      alignment: Alignment.center,
                                      decoration:
                                          OrderStyles.unitPillDecoration,
                                      child: Text(
                                        text(item['quantity']),
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
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () {
                                      onRemove(index);
                                      setModalState(() {});
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
                        money(cartTotal),
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
                    onPressed: onCheckout,
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
