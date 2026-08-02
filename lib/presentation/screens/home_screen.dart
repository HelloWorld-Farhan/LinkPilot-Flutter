import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../providers/database_provider.dart';
import 'add_links_screen.dart';
import '../../data/models/history_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppTheme.ink,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              titlePadding: EdgeInsets.zero,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF091413),
                      Color(0xFF285A48),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.mint.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.mint.withOpacity(0.25)),
                          ),
                          child: const Icon(Icons.link_rounded, color: AppTheme.mint, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'LinkPilot',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${history.length} report${history.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.mint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          if (history.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.mint.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.mint.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(Icons.article_outlined, size: 52, color: AppTheme.teal),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No reports yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to create your first link report',
                      style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildHistoryCard(context, ref, history[index], index),
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),

      // ── FAB ────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const AddLinksScreen(),
            transitionsBuilder: (_, a, __, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Report', style: TextStyle(fontWeight: FontWeight.w700)),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 1.0, curve: Curves.easeOutBack),
    );
  }

  // ── History Card ────────────────────────────────────────────────────────
  Widget _buildHistoryCard(BuildContext context, WidgetRef ref, HistoryItem item, int index) {
    final isSent = item.status == 'Sent';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.mint.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forest.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showHistoryDetails(context, ref, item),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF285A48), Color(0xFF408A71)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.reportName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, yyyy · h:mm a').format(item.generatedAt),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSent
                                ? AppTheme.mint.withOpacity(0.4)
                                : AppTheme.mint.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isSent ? '✅ Sent' : '📄 Saved',
                            style: TextStyle(
                              color: isSent ? AppTheme.forest : AppTheme.teal,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _confirmDelete(context, ref, item),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip(Icons.link_rounded, '${item.totalLinks} Links'),
                    const SizedBox(width: 8),
                    Flexible(child: _chip(Icons.email_outlined, item.recipientEmail)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.15);
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.mint.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.mint.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.teal),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, HistoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Report?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'This will permanently remove all links and records. This action cannot be undone.',
          style: TextStyle(color: AppTheme.textGrey, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ref.read(historyListProvider.notifier).removeHistory(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Report deleted.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDetails(BuildContext context, WidgetRef ref, HistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistoryDetailSheet(item: item, ref: ref),
    );
  }
}

// ── History Detail Sheet ───────────────────────────────────────────────────
class _HistoryDetailSheet extends StatelessWidget {
  final HistoryItem item;
  final WidgetRef ref;
  const _HistoryDetailSheet({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isSent = item.status == 'Sent';
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          // Header strip
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF091413), Color(0xFF285A48)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.mint.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_rounded, color: AppTheme.mint, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.reportName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.mint.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSent ? '✅ Sent via Email' : '📄 PDF Generated',
                          style: const TextStyle(color: AppTheme.mint, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  _sectionCard([
                    _infoRow(Icons.access_time_rounded, 'Generated',
                        DateFormat('EEE, MMM d · h:mm a').format(item.generatedAt)),
                    _divider(),
                    _infoRow(Icons.email_outlined, 'Recipient', item.recipientEmail),
                    _divider(),
                    _infoRow(Icons.send_rounded, 'Sender', 'linkpilot.support@gmail.com'),
                    _divider(),
                    _infoRow(Icons.link_rounded, 'Links', '${item.totalLinks} included'),
                  ]),
                  const SizedBox(height: 16),

                  // Drive link
                  if (item.driveLink != null) ...[
                    const Text('PDF Report',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.forest)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse(item.driveLink!);
                              try {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } catch (e) {
                                debugPrint("Could not launch $uri: $e");
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF285A48), Color(0xFF408A71)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.forest.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Open PDF',
                                      style: TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: item.driveLink!));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('Drive link copied!'),
                              backgroundColor: AppTheme.forest,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.mint.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.mint.withOpacity(0.6)),
                            ),
                            child: const Icon(Icons.copy_rounded, color: AppTheme.forest),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Links list
                  const Text('Included Links',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.forest)),
                  const SizedBox(height: 10),
                  _sectionCard(
                    item.companies.asMap().entries.map((e) {
                      final isLast = e.key == item.companies.length - 1;
                      final url = (item.urls != null && item.urls!.length > e.key) ? item.urls![e.key] : null;
                      return Column(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [Color(0xFF285A48), Color(0xFF408A71)]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('${e.key + 1}',
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(e.value,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                            ),
                            if (url != null) ...[
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: url));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: const Text('Link copied!'),
                                    backgroundColor: AppTheme.forest,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.mint.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.forest),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final uri = Uri.parse(url);
                                  try {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } catch (err) {
                                    debugPrint("Could not launch $uri: $err");
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.forest.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.open_in_new_rounded, size: 18, color: AppTheme.forest),
                                ),
                              ),
                            ] else ...[
                              const Icon(Icons.link_rounded, size: 16, color: AppTheme.teal),
                            ],
                          ]),
                        ),
                        if (!isLast) Divider(height: 1, color: AppTheme.mint.withOpacity(0.4), indent: 60),
                      ]);
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.mint.withOpacity(0.5), width: 1.5),
        ),
        child: Column(children: children),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 18, color: AppTheme.teal),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.textDark, fontSize: 13),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _divider() => Divider(height: 1, color: AppTheme.mint.withOpacity(0.4), indent: 46);
}
