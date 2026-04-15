import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/scan_result_model.dart';

/// Result type returned when the user taps Share.
/// The parent screen is responsible for calling the native share API.
enum ScanResultAction { share }

class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    super.key,
    required this.result,
  });

  final ScanResultModel result;

  Future<void> _openUrl(BuildContext context, String value) async {
    var url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final canOpen = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (canOpen) {
      Navigator.pop(context);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentType = result.contentType;
    final isUrl = contentType == 'url';
    final isEmail = contentType == 'email';
    final isPhone = contentType == 'phone';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(contentType), color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  _titleFor(contentType),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                result.value,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 20),
            // Open button for URLs, emails, phones
            if (isUrl || isEmail || isPhone) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openActionable(context),
                  icon: Icon(_actionIcon(contentType)),
                  label: Text(_actionLabel(contentType)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Return the share action — the parent screen will
                      // invoke the native share sheet from its own context.
                      Navigator.pop(context, ScanResultAction.share);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openActionable(BuildContext context) {
    final value = result.value.trim();
    switch (result.contentType) {
      case 'url':
        _openUrl(context, value);
      case 'email':
        final email = value.startsWith('mailto:') ? value : 'mailto:$value';
        final uri = Uri.tryParse(email);
        if (uri != null) {
          Navigator.pop(context);
          launchUrl(uri);
        }
      case 'phone':
        final phone = value.startsWith('tel:') ? value : 'tel:$value';
        final uri = Uri.tryParse(phone);
        if (uri != null) {
          Navigator.pop(context);
          launchUrl(uri);
        }
    }
  }

  IconData _iconFor(String contentType) {
    return switch (contentType) {
      'url' => Icons.link,
      'email' => Icons.email,
      'phone' => Icons.phone,
      _ => Icons.text_fields,
    };
  }

  String _titleFor(String contentType) {
    return switch (contentType) {
      'url' => 'URL Detected',
      'email' => 'Email Detected',
      'phone' => 'Phone Number Detected',
      _ => 'Text Scanned',
    };
  }

  IconData _actionIcon(String contentType) {
    return switch (contentType) {
      'url' => Icons.open_in_browser,
      'email' => Icons.email_outlined,
      'phone' => Icons.call,
      _ => Icons.open_in_new,
    };
  }

  String _actionLabel(String contentType) {
    return switch (contentType) {
      'url' => 'Open URL',
      'email' => 'Send Email',
      'phone' => 'Call',
      _ => 'Open',
    };
  }
}