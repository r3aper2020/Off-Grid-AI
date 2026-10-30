import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';

/// The single app database. Tests override this with an in-memory instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// App-private directory holding photos attached to chat messages.
/// Overridden in `main`; tests get a temp directory by default.
final photosDirectoryProvider = Provider<Directory>(
  (ref) => Directory('${Directory.systemTemp.path}/offgrid_test_photos'),
);
