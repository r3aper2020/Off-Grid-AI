import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../app/theme/app_colors.dart';

/// Lets the user take or choose a photo for a message and stores a
/// downsized copy in the app's photos directory. Returns the stored file
/// name (relative to [directory]), or null if nothing was picked.
///
/// Photos are resized to at most [maxSide] pixels on the long side: a
/// vision model reads a photo as hundreds of tokens, and on a phone CPU
/// every one of them costs time before the first word.
class PhotoPicker {
  PhotoPicker(this.directory, {ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final Directory directory;
  final ImagePicker _picker;

  static const maxSide = 768.0;
  static const quality = 85;

  /// Shows a sheet to take a photo or choose one, then stores it.
  Future<String?> pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.accent,
              ),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.accent,
              ),
              title: const Text('Choose from photos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
    );
    if (picked == null) return null;
    return store(await picked.readAsBytes(), p.extension(picked.path));
  }

  /// Writes [bytes] into the photos directory under a unique name.
  Future<String> store(List<int> bytes, String extension) async {
    await directory.create(recursive: true);
    final ext = extension.isEmpty ? '.jpg' : extension.toLowerCase();
    final name = '${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(p.join(directory.path, name)).writeAsBytes(bytes, flush: true);
    return name;
  }
}
