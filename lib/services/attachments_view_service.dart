import 'package:flutter/material.dart';
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
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: photos.isEmpty
                          ? const Center(child: Text('No photos'))
                          : GridView.builder(
                              itemCount: photos.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 3 : 5,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                  ),
                              itemBuilder: (_, index) {
                                final p = photos[index];

                                return Stack(
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          zoomPhoto(context: context, photo: p),
                                      child: Image.network(
                                        _text(p['image_url']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await onDelete(p);
                                          refreshModal(() {});
                                        },
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
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(_text(photo['image_url'])),
        ),
      ),
    );
  }
}
