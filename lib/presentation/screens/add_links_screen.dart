import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/url_parser.dart';
import '../providers/database_provider.dart';
import 'preview_screen.dart';

class AddLinksScreen extends ConsumerStatefulWidget {
  const AddLinksScreen({super.key});

  @override
  ConsumerState<AddLinksScreen> createState() => _AddLinksScreenState();
}

class _AddLinksScreenState extends ConsumerState<AddLinksScreen> {
  final List<TextEditingController> _controllers = [TextEditingController()];
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    // Default fallback
    _emailController.text = "LinkPilot.support@gmail.com";
  }

  void _addRows(int count) {
    setState(() {
      for (int i = 0; i < count; i++) {
        _controllers.add(TextEditingController());
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
      // Validate all URLs
      List<String> validUrls = [];
      for (var controller in _controllers) {
        if (controller.text.isNotEmpty) {
          if (!UrlParser.isValidUrl(controller.text)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid URL: ${controller.text}')),
            );
            return;
          }
          validUrls.add(controller.text);
        }
      }

      if (validUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one valid link')),
        );
        return;
      }

      // TODO: Implement Apps Script call and PDF Generation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing...')),
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
              var controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'https://...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye_outlined),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PreviewScreen(url: controller.text),
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
              child: const Text('Generate & Send'),
            ).animate().fadeIn().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
