import 'package:flutter/material.dart';

class MoreToolsSheet extends StatelessWidget {
  const MoreToolsSheet({
    super.key,
    required this.onModifyScan,
    required this.onSaveAsJpeg,
    required this.onEditText,
    required this.onExportPdf,
    required this.onCombineFiles,
    required this.onExtractPages,
    required this.onCompressPdf,
    required this.onSetPassword,
    required this.onFillSign,
    required this.onPrint,
    required this.onAddPages,
    required this.onDelete,
  });

  final VoidCallback onModifyScan;
  final VoidCallback onSaveAsJpeg;
  final VoidCallback onEditText;
  final VoidCallback onExportPdf;
  final VoidCallback onCombineFiles;
  final VoidCallback onExtractPages;
  final VoidCallback onCompressPdf;
  final VoidCallback onSetPassword;
  final VoidCallback onFillSign;
  final VoidCallback onPrint;
  final VoidCallback onAddPages;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'More Tools',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRow(context, [
              _ToolItem(
                icon: Icons.crop_rotate,
                label: 'Modify Scan',
                color: Colors.blue,
                onTap: onModifyScan,
              ),
              _ToolItem(
                icon: Icons.image_outlined,
                label: 'Save as JPEG',
                color: Colors.green,
                onTap: onSaveAsJpeg,
              ),
              _ToolItem(
                icon: Icons.text_fields,
                label: 'Edit Text (OCR)',
                color: Colors.orange,
                onTap: onEditText,
              ),
              _ToolItem(
                icon: Icons.picture_as_pdf,
                label: 'Export PDF',
                color: Colors.red,
                onTap: onExportPdf,
              ),
            ]),
            const SizedBox(height: 12),
            _buildRow(context, [
              _ToolItem(
                icon: Icons.merge_type,
                label: 'Combine Files',
                color: Colors.purple,
                onTap: onCombineFiles,
              ),
              _ToolItem(
                icon: Icons.content_cut,
                label: 'Extract Pages',
                color: Colors.teal,
                onTap: onExtractPages,
              ),
              _ToolItem(
                icon: Icons.compress,
                label: 'Compress PDF',
                color: Colors.indigo,
                onTap: onCompressPdf,
              ),
              _ToolItem(
                icon: Icons.lock_outline,
                label: 'Set Password',
                color: Colors.amber.shade700,
                onTap: onSetPassword,
              ),
            ]),
            const SizedBox(height: 12),
            _buildRow(context, [
              _ToolItem(
                icon: Icons.draw_outlined,
                label: 'Fill & Sign',
                color: Colors.deepPurple,
                onTap: onFillSign,
              ),
              _ToolItem(
                icon: Icons.print,
                label: 'Print',
                color: Colors.cyan,
                onTap: onPrint,
              ),
              _ToolItem(
                icon: Icons.add_photo_alternate,
                label: 'Add Pages',
                color: Colors.lightGreen,
                onTap: onAddPages,
              ),
              _ToolItem(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Colors.red.shade700,
                onTap: onDelete,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<_ToolItem> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items
          .map((item) => Expanded(child: _buildToolButton(context, item)))
          .toList(),
    );
  }

  Widget _buildToolButton(BuildContext context, _ToolItem item) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        item.onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}
