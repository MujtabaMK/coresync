import 'package:flutter/material.dart';

class MedicineTypeSheet extends StatelessWidget {
  const MedicineTypeSheet({super.key});

  static final _types = <(String, IconData)>[
    ('Tablet', Icons.medication),
    ('Capsule', Icons.medication_liquid),
    ('Drop', Icons.water_drop),
    ('Injection', Icons.vaccines),
    ('Puff', Icons.air),
    ('Spray', Icons.blur_on),
    ('Grams', Icons.scale),
    ('Micrograms', Icons.science),
    ('Miligrams', Icons.science_outlined),
    ('Ml', Icons.local_drink),
    ('Tablespoon', Icons.soup_kitchen),
    ('Teaspoon', Icons.coffee),
  ];

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const MedicineTypeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Medicine Type',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _types.length,
                itemBuilder: (context, index) {
                  final (name, icon) = _types[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      child: Icon(icon,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(name),
                    onTap: () => Navigator.pop(context, name),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
