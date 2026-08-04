import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
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
  final ScrollController _mainScrollController = ScrollController();

  bool _sendEmail = true;
  bool _isLoading = false;
  String? _reportNameError;

  @override
  void dispose() {
    _emailController.dispose();
    _reportNameController.dispose();
    _mainScrollController.dispose();
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
    if (_controllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You need at least one link entry.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  void _validateReportName(String value, List<HistoryItem> history) {
    if (value.isEmpty) {
      setState(() => _reportNameError = 'Report name is required');
      return;
    }
    final exists = history.any((h) => h.reportName.toLowerCase() == value.toLowerCase());
    setState(() {
      _reportNameError = exists ? 'A report with this name already exists' : null;
    });
  }

  Future<void> _generateAndSend() async {
    FocusScope.of(context).unfocus();
    final history = ref.read(historyListProvider);

    if (_reportNameController.text.isEmpty) {
      setState(() => _reportNameError = 'Report name is required');
      return;
    }
    if (_reportNameError != null) return;

    if (history.any((h) =>
        h.reportName.toLowerCase() == _reportNameController.text.toLowerCase())) {
      setState(() => _reportNameError = 'A report with this name already exists');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      _mainScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Validate links
    final List<Map<String, String>> validLinks = [];

    for (var entry in _controllers) {
      final name = entry.nameController.text.trim();
      final url = entry.urlController.text.trim();

      if (name.isEmpty && url.isEmpty) continue;

      validLinks.add({'company': name, 'url': url});
    }

    if (validLinks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one valid link')),
      );
      return;
    }

    // Show animated progress sheet
    _showProgressSheet(validLinks);
  }

  void _showProgressSheet(List<Map<String, String>> validLinks) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProcessingSheet(
        reportName: _reportNameController.text,
        recipientEmail: _emailController.text,
        sendEmail: _sendEmail,
        validLinks: validLinks,
        ref: ref,
        onComplete: (String? driveLink, bool success, String? error) {
          Navigator.pop(ctx); // close sheet
          if (success) {
            _onSuccess(driveLink, validLinks, isError: false);
          } else {
            // Force save to history because email might have sent correctly
            _onSuccess(driveLink, validLinks, isError: true, errorMessage: error);
          }
        },
      ),
    );
  }

  void _onSuccess(String? driveLink, List<Map<String, String>> validLinks, {bool isError = false, String? errorMessage}) async {
    // Save to DB via provider (handles both isar write + state update)
    final historyItem = HistoryItem()
      ..reportName = _reportNameController.text
      ..recipientEmail = _emailController.text
      ..generatedAt = DateTime.now()
      ..totalLinks = validLinks.length
      ..driveLink = driveLink
      ..status = isError ? 'Error (Saved)' : (_sendEmail ? 'Sent' : 'Generated')
      ..companies = validLinks.map((e) => e['company']!).toList()
      ..urls = validLinks.map((e) => e['url']!).toList();

    await ref.read(historyListProvider.notifier).addHistory(historyItem);

    if (!mounted) return;

    if (isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'An unknown error occurred, but history was saved.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report generated successfully!'),
          backgroundColor: AppTheme.forest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      // Auto-redirect to home
      Navigator.pop(context);
    }
  }

  void _showSuccessDialog(String? driveLink) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.forest, AppTheme.mint],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forest.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ).animate().scale(begin: const Offset(0, 0), duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              const Text(
                'Report Ready!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _sendEmail
                    ? 'Your PDF was generated and emailed to ${_emailController.text}'
                    : 'Your PDF has been saved to Google Drive.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textGrey, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (driveLink != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open PDF'),
                        onPressed: () async {
                          final uri = Uri.parse(driveLink);
                          if (await canLaunchUrl(uri)) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: driveLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Drive link copied!'),
                            backgroundColor: AppTheme.forest,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mint,
                        foregroundColor: AppTheme.forest,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                      ),
                      child: const Icon(Icons.copy_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('New Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.forest,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: _isLoading ? null : _generateAndSend,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _mainScrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Report Name
            _buildLabel('Report Name', Icons.folder_special_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reportNameController,
              decoration: InputDecoration(
                hintText: 'e.g. Job Applications Oct 2025',
                errorText: _reportNameError,
                prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
              ),
              onChanged: (val) => _validateReportName(val, history),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Report name is required';
                return _reportNameError;
              },
            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),

            // Recipient Email
            _buildLabel('Recipient Email', Icons.email_rounded),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Where to send the report?',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Recipient email is required';
                if (!UrlParser.isValidEmail(val)) return 'Enter a valid email address';
                return null;
              },
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Sent from: linkpilot.support@gmail.com',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.forest.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Send Email Report',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
                subtitle: Text(
                  _sendEmail
                      ? 'PDF will be emailed to recipient'
                      : 'Only PDF will be saved to Drive',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
                value: _sendEmail,
                activeColor: AppTheme.forest,
                onChanged: (val) => setState(() => _sendEmail = val),
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
            const SizedBox(height: 28),

            // Links section
            _buildLabel('Links', Icons.link_rounded).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),

            ..._controllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final data = entry.value;
              return _buildLinkRow(idx, data);
            }),

            const SizedBox(height: 32),

            // Generate button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.forest, AppTheme.mint],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forest.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateAndSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Generate & Process',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.forest),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkRow(int idx, LinkEntryData data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.forest.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: number badge + action icons
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        color: AppTheme.forest,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
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
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.mint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.open_in_new_rounded, size: 16, color: AppTheme.forest),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeRow(idx),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Name field - full width so whole name shows
            TextFormField(
              controller: data.nameController,
              decoration: InputDecoration(
                hintText: 'Company / Link Name',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                prefixIcon: const Icon(Icons.business_rounded, size: 18, color: AppTheme.forest),
                fillColor: AppTheme.mint,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              validator: (val) {
                if (data.urlController.text.isNotEmpty && (val == null || val.isEmpty)) {
                  return 'Name required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            // URL field - full width
            TextFormField(
              controller: data.urlController,
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                prefixIcon: const Icon(Icons.link_rounded, size: 18, color: AppTheme.forest),
                fillColor: AppTheme.mint,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
              keyboardType: TextInputType.url,
              onChanged: (val) {
                if (val.isNotEmpty && data.nameController.text.isEmpty) {
                  final name = UrlParser.extractCompanyName(val);
                  if (name.isNotEmpty) {
                    setState(() => data.nameController.text = name);
                  }
                }
                if (val.isNotEmpty && idx == _controllers.length - 1) {
                  _addRows(1);
                }
              },
              validator: (val) {
                if (data.nameController.text.isNotEmpty && (val == null || val.isEmpty)) {
                  return 'URL required';
                }
                return null;
              },
            ),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05),
    );
  }
}

// ——————————————————————————————————————————————————————————————————————————————

class _ProcessingSheet extends ConsumerStatefulWidget {
  final String reportName;
  final String recipientEmail;
  final bool sendEmail;
  final List<Map<String, String>> validLinks;
  final WidgetRef ref;
  final void Function(String? driveLink, bool success, String? error) onComplete;

  const _ProcessingSheet({
    required this.reportName,
    required this.recipientEmail,
    required this.sendEmail,
    required this.validLinks,
    required this.ref,
    required this.onComplete,
  });

  @override
  ConsumerState<_ProcessingSheet> createState() => _ProcessingSheetState();
}

class _Step {
  final IconData icon;
  final String label;
  final String detail;
  const _Step({required this.icon, required this.label, required this.detail});
}

class _ProcessingSheetState extends ConsumerState<_ProcessingSheet>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isDone = false;
  bool _isError = false;
  String? _errorMsg;
  String? _driveLink;
  final ScrollController _scrollController = ScrollController();

  late final List<_Step> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      const _Step(icon: Icons.link_rounded,          label: 'Packaging links',       detail: 'Compiling all your URLs into a structured report'),
      const _Step(icon: Icons.picture_as_pdf_rounded, label: 'Generating PDF',        detail: 'Converting your links into a beautiful PDF document'),
      const _Step(icon: Icons.cloud_upload_rounded,   label: 'Uploading to Drive',    detail: 'Saving your PDF securely to Google Drive'),
      if (widget.sendEmail)
        const _Step(icon: Icons.email_rounded,        label: 'Sending email',         detail: 'Dispatching report to your recipient'),
      const _Step(icon: Icons.check_circle_rounded,   label: 'All done!',             detail: 'Your report is ready to view'),
    ];
    _runProcess();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToStep(int step) {
    final itemHeight = 88.0;
    final offset = (step * itemHeight).clamp(0.0, double.infinity);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _runProcess() async {
    // Animate through steps visually first
    for (int i = 0; i < _steps.length - 1; i++) {
      if (!mounted) return;
      setState(() => _currentStep = i);
      _scrollToStep(i);
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    // Actually call backend
    final response = await BackendService.generateAndProcess(
      reportName: widget.reportName,
      recipientEmail: widget.recipientEmail,
      sendEmail: widget.sendEmail,
      links: widget.validLinks,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      _driveLink = response['driveLink'] as String?;
      setState(() {
        _currentStep = _steps.length - 1;
        _isDone = true;
      });
      _scrollToStep(_steps.length - 1);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) widget.onComplete(_driveLink, true, null);
    } else {
      setState(() {
        _isError = true;
        _errorMsg = response['error']?.toString() ?? 'Unknown error';
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) widget.onComplete(null, false, _errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF091413), Color(0xFF285A48)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 14),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.mint.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.mint.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.mint, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Processing Report',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      widget.reportName,
                      style: TextStyle(fontSize: 12, color: AppTheme.mint.withOpacity(0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Steps list (scrollable)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (ctx, index) => _buildStep(index),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep(int index) {
    final step = _steps[index];
    final isActive = index == _currentStep && !_isDone && !_isError;
    final isDone = (index < _currentStep) || _isDone;
    final isPending = index > _currentStep && !_isDone;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDone
            ? AppTheme.mint.withOpacity(0.12)
            : isActive
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(color: AppTheme.mint.withOpacity(0.4), width: 1.5)
            : isDone
                ? Border.all(color: AppTheme.teal.withOpacity(0.3))
                : null,
      ),
      child: Row(
        children: [
          // Icon circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? AppTheme.teal
                  : isActive
                      ? AppTheme.forest
                      : Colors.white.withOpacity(0.07),
              boxShadow: (isDone || isActive)
                  ? [BoxShadow(color: AppTheme.teal.withOpacity(0.3), blurRadius: 12)]
                  : null,
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    .animate().scale(duration: 300.ms, curve: Curves.elasticOut)
                : isActive
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.mint,
                        ),
                      )
                    : Icon(step.icon,
                        color: isPending ? Colors.white24 : AppTheme.mint,
                        size: 18),
          ),
          const SizedBox(width: 14),

          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isPending ? Colors.white30 : Colors.white,
                  ),
                ),
                if (isActive || isDone)
                  Text(
                    step.detail,
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.55)),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.05, end: 0),
              ],
            ),
          ),

          // Step number
          if (isPending)
            Text('${index + 1}', style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}




