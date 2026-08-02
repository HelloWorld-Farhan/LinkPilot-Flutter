import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/url_parser.dart';
import '../../core/services/backend_service.dart';
import '../../data/models/history_item.dart';
import '../providers/database_provider.dart';
import 'preview_screen.dart';

class LinkEntryData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController urlController = TextEditingController();

  void dispose() {
    nameController.dispose();
    urlController.dispose();
  }
}

class AddLinksScreen extends ConsumerStatefulWidget {
  const AddLinksScreen({super.key});

  @override
  ConsumerState<AddLinksScreen> createState() => _AddLinksScreenState();
}

class _AddLinksScreenState extends ConsumerState<AddLinksScreen> {
  final List<LinkEntryData> _controllers = [LinkEntryData()];
  final _emailController = TextEditingController();
  final _reportNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _sendEmail = true;
  bool _isLoading = false;
  String? _reportNameError;
  
  @override
  void dispose() {
    _emailController.dispose();
    _reportNameController.dispose();
    for (var entry in _controllers) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addRows(int count) {
    setState(() {
      for (int i = 0; i < count; i++) {
        _controllers.add(LinkEntryData());
      }
    });
  }

  void _removeRow(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  void _validateReportName(String value, List<HistoryItem> history) {
    if (value.isEmpty) {
      setState(() => _reportNameError = 'Required');
      return;
    }
    final exists = history.any((h) => h.reportName.toLowerCase() == value.toLowerCase());
    setState(() {
      _reportNameError = exists ? 'A report with this name already exists' : null;
    });
  }

  Future<void> _generateAndSend() async {
    if (_reportNameError != null) return;
    
    if (_formKey.currentState?.validate() ?? false) {
      final history = ref.read(historyListProvider);
      if (history.any((h) => h.reportName.toLowerCase() == _reportNameController.text.toLowerCase())) {
        setState(() => _reportNameError = 'A report with this name already exists');
        return;
      }

      // Validate all URLs and Names uniquely
      List<Map<String, String>> validLinks = [];
      Set<String> uniqueLinkNames = {};

      for (var entry in _controllers) {
        if (entry.urlController.text.isNotEmpty || entry.nameController.text.isNotEmpty) {
          final name = entry.nameController.text.trim();
          if (name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please provide a name for all links')),
            );
            return;
          }
          if (uniqueLinkNames.contains(name.toLowerCase())) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Duplicate link name found: $name. All names must be unique.')),
            );
            return;
          }
          uniqueLinkNames.add(name.toLowerCase());

          if (!UrlParser.isValidUrl(entry.urlController.text)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid URL: ${entry.urlController.text}')),
            );
            return;
          }
          validLinks.add({
            'company': name,
            'url': entry.urlController.text,
          });
        }
      }

      if (validLinks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one valid link')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final response = await BackendService.generateAndProcess(
        reportName: _reportNameController.text,
        recipientEmail: _emailController.text,
        sendEmail: _sendEmail,
        links: validLinks,
      );

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        final driveLink = response['driveLink'] as String?;
        
        // Save to Database
        final isar = ref.read(isarProvider);
        final historyItem = HistoryItem()
          ..reportName = _reportNameController.text
          ..recipientEmail = _emailController.text
          ..generatedAt = DateTime.now()
          ..totalLinks = validLinks.length
          ..driveLink = driveLink
          ..status = _sendEmail ? 'Sent' : 'Generated'
          ..companies = validLinks.map((e) => e['company']!).toList();
          
        await isar.writeTxn(() async {
          await isar.historyItems.put(historyItem);
        });

        if (!mounted) return;

        if (_sendEmail) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report generated and email sent successfully!')),
          );
          Navigator.pop(context);
        } else {
          _showDriveLinkDialog(driveLink);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${response['error'] ?? 'Unknown error'}')),
          );
        }
      }
    }
  }

  void _showDriveLinkDialog(String? driveLink) {
    if (driveLink == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PDF Generated Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your PDF report is ready on Google Drive.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(driveLink, style: const TextStyle(fontSize: 12)),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: driveLink));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () {
              launchUrl(Uri.parse(driveLink));
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text('Preview'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Links'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _generateAndSend,
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _reportNameController,
                  decoration: InputDecoration(
                    labelText: 'Report / Collection Name',
                    prefixIcon: const Icon(Icons.folder_special_outlined),
                    errorText: _reportNameError,
                  ),
                  onChanged: (val) => _validateReportName(val, history),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    return _reportNameError;
                  },
                ).animate().fadeIn().slideY(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'Where should we send this?',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (!UrlParser.isValidEmail(val)) return 'Enter a valid email';
                    return null;
                  },
                ).animate().fadeIn().slideY(),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Send Email Report'),
                  subtitle: const Text('If disabled, only the PDF will be generated on Drive.'),
                  value: _sendEmail,
                  onChanged: (val) {
                    setState(() => _sendEmail = val);
                  },
                ).animate().fadeIn().slideY(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Links',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('+ 1'),
                          onPressed: () => _addRows(1),
                        ),
                        ActionChip(
                          label: const Text('+ 2'),
                          onPressed: () => _addRows(2),
                        ),
                        ActionChip(
                          label: const Text('+ 5'),
                          onPressed: () => _addRows(5),
                        ),
                        ActionChip(
                          label: const Text('+ 10'),
                          onPressed: () => _addRows(10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._controllers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var data = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: data.nameController,
                            decoration: InputDecoration(
                              hintText: 'Name (e.g. Google)',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (val) {
                              if (data.urlController.text.isNotEmpty && (val == null || val.isEmpty)) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: data.urlController,
                            decoration: InputDecoration(
                              hintText: 'https://...',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (val) {
                              if (data.nameController.text.isNotEmpty && (val == null || val.isEmpty)) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye_outlined),
                          onPressed: () {
                            if (data.urlController.text.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PreviewScreen(url: data.urlController.text),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a URL first')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _removeRow(idx),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1),
                  );
                }),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _generateAndSend,
                  child: const Text('Generate & Process'),
                ).animate().fadeIn().slideY(begin: 0.2),
              ],
            ),
          ),
    );
  }
}
