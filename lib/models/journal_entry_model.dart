import 'package:hive/hive.dart';

part 'journal_entry_model.g.dart';

@HiveType(typeId: 1)
class JournalEntryModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? hikeId;

  JournalEntryModel({
    required this.title,
    required this.content,
    required this.date,
    this.hikeId,
  });
}
