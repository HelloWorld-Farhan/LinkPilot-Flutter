import 'package:isar/isar.dart';

part 'link_item.g.dart';

@collection
class LinkItem {
  Id id = Isar.autoIncrement;

  late String url;
  
  late String companyName;

  bool isCompleted = false;

  late DateTime createdAt;
}

// force rebuild
