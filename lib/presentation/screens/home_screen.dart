import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/database_provider.dart';
import 'add_links_screen.dart';
import '../../data/models/history_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyListProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('LinkPilot History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No reports generated yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ).animate().fadeIn(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildHistoryCard(context, item, index);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLinksScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
      ).animate().fadeIn().slideY(begin: 1.0, curve: Curves.easeOutBack),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showHistoryDetails(context, item),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.reportName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.status == 'Sent' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: item.status == 'Sent' ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, ref, item),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.link, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('${item.totalLinks} Links', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, h:mm a').format(item.generatedAt),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text(
            'This deletion will permanently remove all links in this report and terminate this record. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(historyListProvider.notifier).removeHistory(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report deleted successfully.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHistoryDetails(BuildContext context, HistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              item.reportName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('To: ${item.recipientEmail}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            if (item.driveLink != null) ...[
              InkWell(
                onTap: () => launchUrl(Uri.parse(item.driveLink!)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.blue),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'View PDF on Google Drive',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.open_in_new, color: Colors.blue, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Included Links',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: item.companies.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF3F4F6),
                      child: Icon(Icons.link, color: Colors.black54),
                    ),
                    title: Text(item.companies[index], style: const TextStyle(fontWeight: FontWeight.w500)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
