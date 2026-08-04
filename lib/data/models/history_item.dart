import 'package:isar/isar.dart';

part 'history_item.g.dart';

@collection
class HistoryItem {
  Id id = Isar.autoIncrement;

  late String reportName;

  late DateTime generatedAt;

  late String recipientEmail;

  late int totalLinks;

  String? driveLink;

  late String status; // e.g. "Sent", "Generated", "Failed"

  late List<String> companies;

  List<String> urls = [];
}

// force rebuild
