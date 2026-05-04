import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/attachments_styles.dart';

class AttachmentsDetailsService {
  static final supabase = Supabase.instance.client;

  static String _statusOf(Map<String, dynamic> order) {
    final status = (order['collecting_status'] ?? '').toString().trim();
    return status.isEmpty ? 'processing' : status.toLowerCase();
  }

  static Future<void> openDetails({
    required BuildContext context,
    required Map<String, dynamic> order,
    required List<Map<String, dynamic>> photos,
    required Future<void> Function() onDone,
  }) async {
    final descController = TextEditingController(
      text: photos.isNotEmpty
          ? (photos.first['procuring_entity'] ?? '').toString()
          : '',
    );

    String status = _statusOf(order);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AttachmentsStyles.bg,
        title: const Text(
          'Write Procuring Entity',
          style: TextStyle(color: AttachmentsStyles.textPrimary),
        ),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: const TextStyle(color: AttachmentsStyles.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Write Procuring Entity...',
                    hintStyle: const TextStyle(
                      color: AttachmentsStyles.textSecondary,
                    ),
                    filled: true,
                    fillColor: AttachmentsStyles.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: AttachmentsStyles.bg,
                  style: const TextStyle(color: AttachmentsStyles.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AttachmentsStyles.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'processing',
                      child: Text('Processing'),
                    ),
                    DropdownMenuItem(
                      value: 'collecting',
                      child: Text('Collecting'),
                    ),
                    DropdownMenuItem(
                      value: 'collected',
                      child: Text('Collected'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => status = v);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await supabase
                  .from('purchase_orders')
                  .update({'collecting_status': status})
                  .eq('id', order['id']);

              if (photos.isNotEmpty) {
                await supabase
                    .from('order_attachments')
                    .update({'procuring_entity': descController.text.trim()})
                    .eq('order_id', order['id']);
              }

              Navigator.pop(context);
              await onDone();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
