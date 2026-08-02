import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/history_item.dart';
import '../../data/models/link_item.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider not initialized');
});

final linkListProvider = StateNotifierProvider<LinkListNotifier, List<LinkItem>>((ref) {
  final isar = ref.watch(isarProvider);
  return LinkListNotifier(isar);
});

class LinkListNotifier extends StateNotifier<List<LinkItem>> {
  final Isar _isar;

  LinkListNotifier(this._isar) : super([]) {
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final links = await _isar.linkItems.where().findAll();
    state = links;
  }

  Future<void> addLink(String url, String companyName) async {
    final newLink = LinkItem()
      ..url = url
      ..companyName = companyName
      ..createdAt = DateTime.now()
      ..isCompleted = false;

    await _isar.writeTxn(() async {
      await _isar.linkItems.put(newLink);
    });
    
    state = [...state, newLink];
  }
  
  Future<void> removeLink(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.linkItems.delete(id);
    });
    
    state = state.where((item) => item.id != id).toList();
  }

  Future<void> toggleComplete(Id id) async {
    final link = state.firstWhere((item) => item.id == id);
    link.isCompleted = !link.isCompleted;

    await _isar.writeTxn(() async {
      await _isar.linkItems.put(link);
    });
    
    // Trigger state update
    state = [
      for (final item in state)
        if (item.id == id) link else item
    ];
  }
}

final historyListProvider = StateNotifierProvider<HistoryListNotifier, List<HistoryItem>>((ref) {
  final isar = ref.watch(isarProvider);
  return HistoryListNotifier(isar);
});

class HistoryListNotifier extends StateNotifier<List<HistoryItem>> {
  final Isar _isar;

  HistoryListNotifier(this._isar) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _isar.historyItems.where().sortByGeneratedAtDesc().findAll();
    state = history;
  }

  Future<void> addHistory(HistoryItem item) async {
    await _isar.writeTxn(() async {
      await _isar.historyItems.put(item);
    });
    state = [item, ...state];
  }
  
  Future<void> clearHistory() async {
    await _isar.writeTxn(() async {
      await _isar.historyItems.clear();
    });
    state = [];
  }

  Future<void> removeHistory(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.historyItems.delete(id);
    });
    state = state.where((item) => item.id != id).toList();
  }
}
