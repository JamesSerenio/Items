import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/attachments_styles.dart';

class AttachmentsViewService {
  static final supabase = Supabase.instance.client;

  static String _text(dynamic v) => v?.toString() ?? '-';

  static num _num(dynamic v) => num.tryParse(v?.toString() ?? '0') ?? 0;

  static String _peso(dynamic v) {
    final n = _num(v);
    final parts = n.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '₱$whole.${parts[1]}';
  }

  static String _formatDate(dynamic value) {
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

  static Future<List<Map<String, dynamic>>> _loadItems(dynamic orderId) async {
    final data = await supabase
        .from('purchase_order_items')
        .select(
          'stock_no, unit, item_description, brand, location, quantity, unit_cost, total_cost, materials(brand)',
        )
        .eq('purchase_order_id', orderId)
        .order('stock_no', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  static String _brandText(Map<String, dynamic> item) {
    final directBrand = (item['brand'] ?? '').toString().trim();
    final material = item['materials'];

    String materialBrand = '';
    if (material is Map) {
      materialBrand = (material['brand'] ?? '').toString().trim();
    }

    final brand = directBrand.isNotEmpty ? directBrand : materialBrand;
    return brand.isEmpty ? '' : ' ($brand)';
  }

  static Future<void> viewPdf({
    required BuildContext context,
    required Map<String, dynamic> order,
  }) async {
    final items = await _loadItems(order['id']);

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) {
        final isMobile = MediaQuery.of(context).size.width < 650;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.all(isMobile ? 10 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: isMobile ? double.infinity : 820,
            height: MediaQuery.of(context).size.height * 0.86,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'PURCHASE ORDER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Procuring Entity: ${_text(order['description'])}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Date: ${_formatDate(order['created_at'])}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 760,
                          child: Column(
                            children: [
                              Table(
                                border: TableBorder.all(color: Colors.black54),
                                columnWidths: const {
                                  0: FlexColumnWidth(0.9),
                                  1: FlexColumnWidth(0.8),
                                  2: FlexColumnWidth(2),
                                  3: FlexColumnWidth(1.3),
                                  4: FlexColumnWidth(0.7),
                                  5: FlexColumnWidth(1.2),
                                  6: FlexColumnWidth(1.2),
                                },
                                children: [
                                  _tableRow([
                                    'STOCK\nNO.',
                                    'UNIT',
                                    'ITEM DESCRIPTION /\nBRAND',
                                    'LOCATION',
                                    'QTY',
                                    'UNIT COST',
                                    'TOTAL COST',
                                  ], header: true),
                                  ...items.map(
                                    (i) => _tableRow([
                                      _text(i['stock_no']),
                                      _text(i['unit']),
                                      '${_text(i['item_description'])}${_brandText(i)}',
                                      _text(i['location']),
                                      _text(i['quantity']),
                                      _peso(i['unit_cost']),
                                      _peso(i['total_cost']),
                                    ]),
                                  ),
                                ],
                              ),
                              Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFEFEF),
                                  border: Border.all(color: Colors.black54),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'TOTAL AMOUNT',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 28),
                                    Text(
                                      _peso(order['total_amount']),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static TableRow _tableRow(List<String> values, {bool header = false}) {
    return TableRow(
      decoration: header
          ? const BoxDecoration(color: Color(0xFFEFEFEF))
          : const BoxDecoration(color: Colors.white),
      children: values.map((v) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            v,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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

  static void viewPhotos({
    required BuildContext context,
    required Map<String, dynamic> order,
    required List<Map<String, dynamic>> photos,
    required Future<void> Function(Map<String, dynamic>) onDelete,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.78),
      builder: (_) {
        final isMobile = MediaQuery.of(context).size.width < 650;

        return StatefulBuilder(
          builder: (context, refreshModal) {
            return Dialog(
              backgroundColor: AttachmentsStyles.bg,
              insetPadding: EdgeInsets.all(isMobile ? 10 : 18),
              child: Container(
                width: isMobile ? double.infinity : 900,
                height: isMobile
                    ? MediaQuery.of(context).size.height * 0.60
                    : MediaQuery.of(context).size.height * 0.86,
                padding: EdgeInsets.all(isMobile ? 14 : 18),
                decoration: AttachmentsStyles.panel,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          color: AttachmentsStyles.gold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Uploaded Photos - ${_text(order['description'])}',
                            style: AttachmentsStyles.title.copyWith(
                              fontSize: isMobile ? 16 : 20,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AttachmentsStyles.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Date: ${_formatDate(order['created_at'])}',
                        style: AttachmentsStyles.small.copyWith(
                          color: AttachmentsStyles.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: photos.isEmpty
                          ? const Center(
                              child: Text(
                                'No uploaded photos yet',
                                style: AttachmentsStyles.subtitle,
                              ),
                            )
                          : GridView.builder(
                              itemCount: photos.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 3 : 5,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: isMobile ? 0.92 : 1.05,
                                  ),
                              itemBuilder: (_, index) {
                                final p = photos[index];

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          zoomPhoto(context: context, photo: p),
                                      child: Container(
                                        decoration: AttachmentsStyles.cardStyle,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          child: Image.network(
                                            _text(p['image_url']),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        onTap: () async {
                                          await onDelete(p);
                                          refreshModal(() {});
                                        },
                                        child: Container(
                                          width: isMobile ? 24 : 30,
                                          height: isMobile ? 24 : 30,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.78,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AttachmentsStyles.danger
                                                  .withOpacity(0.9),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: const Color(0xFFFFB4B4),
                                            size: isMobile ? 15 : 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
      },
    );
  }

  static void zoomPhoto({
    required BuildContext context,
    required Map<String, dynamic> photo,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.90),
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.6,
                maxScale: 5,
                child: Image.network(_text(photo['image_url'])),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
