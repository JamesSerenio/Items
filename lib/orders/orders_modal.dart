import 'package:flutter/material.dart';

import '../styles/order_styles.dart';

class OrdersModal extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final String Function(dynamic value) text;
  final String Function(dynamic value) money;
  final void Function(Map<String, dynamic> order) onOpenOrder;
  final Future<void> Function(Map<String, dynamic> order) onVoidOrder;

  const OrdersModal({
    super.key,
    required this.orders,
    required this.text,
    required this.money,
    required this.onOpenOrder,
    required this.onVoidOrder,
  });

  @override
  Widget build(BuildContext context) {
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
                _MiniPill(text: '${orders.length}'),
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
              child: orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders yet',
                        style: OrderStyles.emptyStyle,
                      ),
                    )
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final order = orders[index];

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onOpenOrder(order),
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
                                        text(order['description']),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: OrderStyles.cartItemNameStyle,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        text(order['po_no']),
                                        style: OrderStyles.cartItemMetaStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      money(order['total_amount']),
                                      style: OrderStyles.orderTotalStyle,
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: () => onVoidOrder(order),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: OrderStyles.dangerColor
                                              .withOpacity(0.13),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
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
