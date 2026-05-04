import 'package:flutter/material.dart';
import '../styles/attachments_styles.dart';

class AttachmentsViewPhotosService {
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

  static void open({
    required BuildContext context,
    required Map<String, dynamic> order,
    required List<Map<String, dynamic>> photos,
    required Future<void> Function(Map<String, dynamic>) onDelete,
  }) {
    final localPhotos = List<Map<String, dynamic>>.from(photos);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) {
        final isMobile = MediaQuery.of(context).size.width < 650;

        return StatefulBuilder(
          builder: (context, refresh) {
            return Dialog(
              backgroundColor: AttachmentsStyles.bg,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AttachmentsStyles.panel,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo, color: AttachmentsStyles.gold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _text(order['description']),
                            style: AttachmentsStyles.title,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),

                    Expanded(
                      child: localPhotos.isEmpty
                          ? const Center(child: Text('No Photos'))
                          : GridView.builder(
                              itemCount: localPhotos.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isMobile ? 3 : 5,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemBuilder: (_, i) {
                                final p = localPhotos[i];

                                return Stack(
                                  children: [
                                    InkWell(
                                      onTap: () => zoom(context, p),
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
                                          localPhotos.removeAt(i);
                                          refresh(() {});
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

  static void zoom(BuildContext context, Map<String, dynamic> photo) {
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
