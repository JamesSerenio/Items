import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttachmentsUploadService {
  static final supabase = Supabase.instance.client;

  static Future<String?> askDescription(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Description'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static Future<void> upload({
    required BuildContext context,
    required Map<String, dynamic> order,
    required List<Map<String, dynamic>> oldPhotos,
    required Function(String) onSnack,
    required Future<void> Function() onDone,
  }) async {
    final desc = await askDescription(context);
    if (desc == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    try {
      for (final file in result.files) {
        if (file.bytes == null) continue;

        final fileName =
            '${order['id']}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

        await supabase.storage
            .from('attachments')
            .uploadBinary(fileName, file.bytes!);

        final url = supabase.storage.from('attachments').getPublicUrl(fileName);

        await supabase.from('order_attachments').insert({
          'order_id': order['id'],
          'image_url': url,
          'file_name': file.name,
          'description': desc,
          'storage_path': fileName,
        });
      }

      await onDone();
      onSnack('Upload success');
    } catch (e) {
      onSnack('Upload failed: $e');
    }
  }
}
