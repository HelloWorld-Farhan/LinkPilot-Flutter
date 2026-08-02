import 'package:isar/isar.dart';

part 'history_item.g.dart';

@collection
class HistoryItem {
  Id id = Isar.autoIncrement;

  late DateTime generatedAt;

  late String senderEmail;

  late int totalLinks;

  late String driveLink;

  late String status; // e.g. "Sent", "Failed"

  late List<String> companies;
}
