// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../styles/documents_styles.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  bool loading = true;
  bool uploading = false;
  String? openedFolder;

  List<String> folders = [];
  List<FileObject> photos = [];

  final Set<String> selectedFolders = {};
  final Set<String> selectedPhotos = {};

  String get rootPath => 'bucket_documents';

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DocumentsStyles.inputFill),
    );
  }

  String cleanFolderName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Future<void> loadFolders() async {
    try {
      setState(() => loading = true);

      final data = await supabase.storage
          .from('attachments')
          .list(path: rootPath);

      final list = data
          .where((e) => e.name != '.emptyFolderPlaceholder')
          .map((e) => e.name)
          .toList();

      setState(() {
        folders = list;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      snack('Load folders failed: $e');
    }
  }

  Future<void> loadPhotos(String folder) async {
    try {
      setState(() {
        loading = true;
        openedFolder = folder;
        selectedPhotos.clear();
      });

      final data = await supabase.storage
          .from('attachments')
          .list(path: '$rootPath/$folder');

      setState(() {
        photos = data.where((e) => e.name != '.keep').toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      snack('Load photos failed: $e');
    }
  }

  Future<void> createFolder() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DocumentsStyles.panelCardColor,
        title: const Text(
          'Create Folder',
          style: TextStyle(
            color: DocumentsStyles.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: DocumentsStyles.textPrimary),
          decoration: DocumentsStyles.searchDecoration('Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: DocumentsStyles.goldButton,
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    final folderName = cleanFolderName(name);

    try {
      await supabase.storage
          .from('attachments')
          .uploadBinary(
            '$rootPath/$folderName/.keep',
            Uint8List.fromList([]),
            fileOptions: const FileOptions(upsert: true),
          );

      await loadFolders();
      snack('Folder created');
    } catch (e) {
      snack('Create folder failed: $e');
    }
  }

  Future<void> uploadPhotos() async {
    if (openedFolder == null) return;

    final currentFolder = openedFolder!;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    try {
      setState(() => uploading = true);

      for (final file in result.files) {
        if (file.bytes == null) continue;

        final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeName';

        await supabase.storage
            .from('attachments')
            .uploadBinary(
              '$rootPath/$currentFolder/$fileName',
              file.bytes!,
              fileOptions: const FileOptions(upsert: false),
            );
      }

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;
      await loadPhotos(currentFolder);

      if (!mounted) return;
      setState(() {
        openedFolder = currentFolder;
        uploading = false;
      });

      snack('Photos uploaded');
    } catch (e) {
      if (mounted) setState(() => uploading = false);
      snack('Upload failed: $e');
    }
  }

  Future<void> deleteSelectedFolders() async {
    if (selectedFolders.isEmpty) return;

    try {
      for (final folder in selectedFolders) {
        final files = await supabase.storage
            .from('attachments')
            .list(path: '$rootPath/$folder');

        final paths = files.map((e) => '$rootPath/$folder/${e.name}').toList();

        if (paths.isNotEmpty) {
          await supabase.storage.from('attachments').remove(paths);
        }
      }

      selectedFolders.clear();
      await loadFolders();
      snack('Selected folders deleted');
    } catch (e) {
      snack('Delete folder failed: $e');
    }
  }

  Future<void> deleteSelectedPhotos() async {
    if (openedFolder == null || selectedPhotos.isEmpty) return;

    try {
      final paths = selectedPhotos
          .map((name) => '$rootPath/$openedFolder/$name')
          .toList();

      await supabase.storage.from('attachments').remove(paths);

      selectedPhotos.clear();
      await loadPhotos(openedFolder!);
      snack('Selected photos deleted');
    } catch (e) {
      snack('Delete photos failed: $e');
    }
  }

  String publicUrl(String path) {
    return supabase.storage.from('attachments').getPublicUrl(path);
  }

  void downloadPhoto(String name) {
    if (openedFolder == null) return;

    final url = publicUrl('$rootPath/$openedFolder/$name');
    final anchor = html.AnchorElement(href: url)
      ..download = name
      ..target = '_blank';

    anchor.click();
  }

  void downloadAllPhotos() {
    if (openedFolder == null) return;

    for (final photo in photos) {
      downloadPhoto(photo.name);
    }
  }

  void viewPhoto(String name) {
    if (openedFolder == null) return;

    final url = publicUrl('$rootPath/$openedFolder/$name');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
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

  List<String> get filteredFolders {
    final q = searchController.text.trim().toLowerCase();
    if (q.isEmpty) return folders;
    return folders.where((f) => f.toLowerCase().contains(q)).toList();
  }

  Widget folderCard(String folder) {
    final selected = selectedFolders.contains(folder);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => loadPhotos(folder),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: selected
            ? DocumentsStyles.selectedCardDecoration
            : DocumentsStyles.cardDecoration,
        child: Row(
          children: [
            Checkbox(
              value: selected,
              activeColor: DocumentsStyles.megaGreen,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    selectedFolders.add(folder);
                  } else {
                    selectedFolders.remove(folder);
                  }
                });
              },
            ),
            const Icon(
              Icons.folder_copy_rounded,
              color: DocumentsStyles.plutoGold,
              size: 34,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                folder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DocumentsStyles.folderName,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: DocumentsStyles.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget photoCard(FileObject photo) {
    final selected = selectedPhotos.contains(photo.name);
    final url = publicUrl('$rootPath/$openedFolder/${photo.name}');

    return Container(
      decoration: selected
          ? DocumentsStyles.selectedCardDecoration
          : DocumentsStyles.cardDecoration,
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => viewPhoto(photo.name),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: DocumentsStyles.textSecondary,
                      size: 45,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  activeColor: DocumentsStyles.megaGreen,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedPhotos.add(photo.name);
                      } else {
                        selectedPhotos.remove(photo.name);
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    photo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DocumentsStyles.small,
                  ),
                ),
                IconButton(
                  onPressed: () => downloadPhoto(photo.name),
                  icon: const Icon(
                    Icons.download_rounded,
                    color: DocumentsStyles.plutoGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget foldersView(bool isMobile) {
    final list = filteredFolders;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: DocumentsStyles.textPrimary),
                decoration: DocumentsStyles.searchDecoration('Search folder'),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: DocumentsStyles.goldButton,
              onPressed: createFolder,
              icon: const Icon(Icons.create_new_folder_rounded),
              label: const Text('Add Folder'),
            ),
            if (selectedFolders.isNotEmpty) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: DocumentsStyles.dangerButton,
                onPressed: deleteSelectedFolders,
                icon: const Icon(Icons.delete_rounded),
                label: Text('Delete ${selectedFolders.length}'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text(
                    'No folder found',
                    style: DocumentsStyles.subtitle,
                  ),
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => folderCard(list[i]),
                ),
        ),
      ],
    );
  }

  Widget photosView(bool isMobile) {
    final allSelected =
        photos.isNotEmpty && selectedPhotos.length == photos.length;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  openedFolder = null;
                  photos.clear();
                  selectedPhotos.clear();
                });
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: DocumentsStyles.plutoGold,
              ),
            ),
            Expanded(
              child: Text(
                openedFolder ?? '',
                overflow: TextOverflow.ellipsis,
                style: DocumentsStyles.title.copyWith(fontSize: 23),
              ),
            ),
            if (photos.isNotEmpty) ...[
              Checkbox(
                value: allSelected,
                activeColor: DocumentsStyles.megaGreen,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      selectedPhotos
                        ..clear()
                        ..addAll(photos.map((p) => p.name));
                    } else {
                      selectedPhotos.clear();
                    }
                  });
                },
              ),
              const Text(
                'Select All',
                style: TextStyle(
                  color: DocumentsStyles.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
            ],
            ElevatedButton.icon(
              style: DocumentsStyles.goldButton,
              onPressed: uploading ? null : uploadPhotos,
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_rounded),
              label: Text(uploading ? 'Uploading...' : 'Add Photos'),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: DocumentsStyles.goldButton,
              onPressed: photos.isEmpty ? null : downloadAllPhotos,
              icon: const Icon(Icons.download_for_offline_rounded),
              label: const Text('Download All'),
            ),
            if (selectedPhotos.isNotEmpty) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: DocumentsStyles.dangerButton,
                onPressed: deleteSelectedPhotos,
                icon: const Icon(Icons.delete_rounded),
                label: Text('Delete ${selectedPhotos.length}'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: photos.isEmpty
              ? const Center(
                  child: Text(
                    'No photos in this folder',
                    style: DocumentsStyles.subtitle,
                  ),
                )
              : GridView.builder(
                  itemCount: photos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isMobile ? 0.75 : 0.85,
                  ),
                  itemBuilder: (_, i) => photoCard(photos[i]),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      decoration: DocumentsStyles.panelDecoration,
      padding: EdgeInsets.all(isMobile ? 16 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (openedFolder == null) ...[
            const Text('Documents', style: DocumentsStyles.title),
            const SizedBox(height: 6),
            const Text(
              'Create folders, upload photos, view, download, and delete documents.',
              style: DocumentsStyles.subtitle,
            ),
            const SizedBox(height: 18),
          ],
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : openedFolder == null
                ? foldersView(isMobile)
                : photosView(isMobile),
          ),
        ],
      ),
    );
  }
}
