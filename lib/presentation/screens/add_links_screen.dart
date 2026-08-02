import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/url_parser.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _sendEmail = true;
  
  @override
  void initState() {
    super.initState();
    // Default fallback
    _emailController.text = "LinkPilot.support@gmail.com";
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

  void _generateAndSend() {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate all URLs and Names
      List<Map<String, String>> validLinks = [];
      for (var entry in _controllers) {
        if (entry.urlController.text.isNotEmpty || entry.nameController.text.isNotEmpty) {
          if (entry.nameController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please provide a name for all links')),
            );
            return;
          }
          if (!UrlParser.isValidUrl(entry.urlController.text)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid URL: ${entry.urlController.text}')),
            );
            return;
          }
          validLinks.add({
            'company': entry.nameController.text,
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

      // TODO: Implement Apps Script call and PDF Generation passing `_sendEmail`
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processing ${validLinks.length} links (Send Email: $_sendEmail)...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Links'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _generateAndSend,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Sender Email',
                prefixIcon: Icon(Icons.email_outlined),
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
              onPressed: _generateAndSend,
              child: const Text('Generate & Process'),
            ).animate().fadeIn().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var entry in _controllers) {
      entry.dispose();
    }
    super.dispose();
  }
}
