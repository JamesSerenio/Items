import 'package:flutter/material.dart';

import '../pdf/attachments_pdf_service.dart';
import '../styles/attachments_styles.dart';

class AttachmentsViewService {
  static String _text(dynamic v) => v?.toString() ?? '-';

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

  static Future<void> viewPdf({
    required BuildContext context,
    required Map<String, dynamic> order,
  }) async {
    await AttachmentsPdfService.viewPdf(context: context, order: order);
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
