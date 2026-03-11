import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'models/hike_model.dart';
import 'models/journal_entry_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters - THIS IS CRITICAL
  Hive.registerAdapter(HikeModelAdapter());
  Hive.registerAdapter(JournalEntryModelAdapter());

  runApp(const ProviderScope(child: TrailNotesApp()));
}
