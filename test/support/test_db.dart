import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:offgrid_ai/core/database/app_database.dart';

/// In-memory database. Synchronous stream closing avoids pending-timer
/// failures in widget tests.
AppDatabase testDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);
