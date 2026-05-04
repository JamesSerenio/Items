import 'package:flutter/material.dart';

import '../styles/order_styles.dart';

class VoidApprovalModal extends StatelessWidget {
  final List<Map<String, dynamic>> voidRequests;
  final String Function(dynamic value) text;
  final Future<void> Function(Map<String, dynamic> request) onApprove;
  final Future<void> Function(Map<String, dynamic> request) onDecline;

  const VoidApprovalModal({
    super.key,
    required this.voidRequests,
    required this.text,
    required this.onApprove,
    required this.onDecline,
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
                  Icons.verified_user_outlined,
                  color: OrderStyles.plutoGold,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Void Approval',
                    style: OrderStyles.cartTitleStyle,
                  ),
                ),
                _MiniPill(text: '${voidRequests.length}'),
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
              child: voidRequests.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending approval',
                        style: OrderStyles.emptyStyle,
                      ),
                    )
                  : ListView.separated(
                      itemCount: voidRequests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final request = voidRequests[index];
                        final order = Map<String, dynamic>.from(
                          request['purchase_orders'] ?? {},
                        );

                        return Container(
                          padding: const EdgeInsets.all(13),
                          decoration: OrderStyles.orderItemDecoration,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.pending_actions_rounded,
                                color: OrderStyles.plutoGold,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const SizedBox(height: 4),
                                    Text(
                                      'Reason: ${text(request['reason'])}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: OrderStyles.cartItemMetaStyle
                                          .copyWith(
                                            color: OrderStyles.plutoGold,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => onApprove(request),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: OrderStyles.primaryColor.withOpacity(
                                      0.13,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: OrderStyles.primaryColor
                                          .withOpacity(0.55),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: OrderStyles.primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => onDecline(request),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: OrderStyles.dangerColor.withOpacity(
                                      0.13,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: OrderStyles.dangerColor
                                          .withOpacity(0.55),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: OrderStyles.dangerColor,
                                    size: 20,
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
