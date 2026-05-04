import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/attachments_styles.dart';

class AttachmentsDetailsService {
  static final supabase = Supabase.instance.client;

  static String _statusOf(Map<String, dynamic> order) {
    final status = (order['collecting_status'] ?? '').toString().trim();
    return status.isEmpty ? 'processing' : status.toLowerCase();
  }

  static DateTime? _dateOf(Map<String, dynamic> order) {
    final raw = order['status_datetime']?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static String _formatDateTime(DateTime? date) {
    if (date == null) return 'Pick date and time';

    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}  $hour:$minute $ampm';
  }

  static Future<DateTime?> _pickDateTime({
    required BuildContext context,
    required DateTime? initial,
  }) async {
    final now = DateTime.now();
    final base = initial ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dialogTheme: const DialogThemeData(insetPadding: EdgeInsets.zero),
            colorScheme: const ColorScheme.dark(
              primary: AttachmentsStyles.gold,
              onPrimary: Colors.black,
              surface: AttachmentsStyles.bg,
              onSurface: AttachmentsStyles.textPrimary,
            ),
          ),
          child: Center(child: Transform.scale(scale: 0.72, child: child!)),
        );
      },
    );

    if (pickedDate == null) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dialogTheme: const DialogThemeData(insetPadding: EdgeInsets.zero),
            colorScheme: const ColorScheme.dark(
              primary: AttachmentsStyles.gold,
              onPrimary: Colors.black,
              surface: AttachmentsStyles.bg,
              onSurface: AttachmentsStyles.textPrimary,
            ),
          ),
          child: Center(child: Transform.scale(scale: 0.70, child: child!)),
        );
      },
    );

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
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
    DateTime? selectedDateTime = _dateOf(order);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AttachmentsStyles.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AttachmentsStyles.gold.withOpacity(0.45)),
        ),
        title: const Text(
          'Write Procuring Entity',
          style: TextStyle(
            color: AttachmentsStyles.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            Color statusColor;

            if (status == 'processing') {
              statusColor = AttachmentsStyles.gold;
            } else if (status == 'collecting') {
              statusColor = AttachmentsStyles.danger;
            } else {
              statusColor = AttachmentsStyles.green;
            }

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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AttachmentsStyles.gold.withOpacity(0.40),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AttachmentsStyles.gold,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AttachmentsStyles.bgDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: statusColor.withOpacity(0.75),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: status,
                        dropdownColor: AttachmentsStyles.bg,
                        style: const TextStyle(
                          color: AttachmentsStyles.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                          ),
                          filled: true,
                          fillColor: AttachmentsStyles.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: statusColor.withOpacity(0.55),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: statusColor,
                              width: 1.6,
                            ),
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
                          if (v != null) {
                            setModalState(() => status = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final picked = await _pickDateTime(
                            context: context,
                            initial: selectedDateTime,
                          );

                          if (picked != null) {
                            setModalState(() {
                              selectedDateTime = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AttachmentsStyles.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: statusColor.withOpacity(0.55),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: statusColor,
                                size: 19,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _formatDateTime(selectedDateTime),
                                  style: TextStyle(
                                    color: selectedDateTime == null
                                        ? AttachmentsStyles.textSecondary
                                        : AttachmentsStyles.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  .update({
                    'collecting_status': status,
                    'status_datetime': selectedDateTime?.toIso8601String(),
                  })
                  .eq('id', order['id']);

              if (photos.isNotEmpty) {
                await supabase
                    .from('order_attachments')
                    .update({'procuring_entity': descController.text.trim()})
                    .eq('order_id', order['id']);
              }

              if (context.mounted) Navigator.pop(context);
              await onDone();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
