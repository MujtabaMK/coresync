import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/common_foods_data.dart';
import '../../data/food_database_service.dart';

class CreateFoodScreen extends StatefulWidget {
  const CreateFoodScreen({super.key, this.initialName});

  final String? initialName;

  @override
  State<CreateFoodScreen> createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends State<CreateFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _servingSizeCtrl = TextEditingController(text: '100g');
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _fiberCtrl = TextEditingController();
  final _sodiumCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _cholesterolCtrl = TextEditingController();

  String _category = 'Other';
  bool _saving = false;

  static const _categories = [
    'Grains',
    'Protein',
    'Dairy',
    'Fruits',
    'Vegetables',
    'Legumes',
    'Snacks',
    'Beverages',
    'Desserts',
    'Fast Food',
    'Indian',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingSizeCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _fiberCtrl.dispose();
    _sodiumCtrl.dispose();
    _sugarCtrl.dispose();
    _cholesterolCtrl.dispose();
    super.dispose();
  }

  double _parseDouble(TextEditingController ctrl) {
    return double.tryParse(ctrl.text.trim()) ?? 0;
  }

  void _pickCategory() {
    showDialog(
      context: context,
      builder: (_) => _SearchableCategoryDialog(
        categories: _categories,
        selected: _category,
        onSelected: (v) => setState(() => _category = v),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final food = CommonFoodItem(
      name: _nameCtrl.text.trim(),
      servingSize: _servingSizeCtrl.text.trim(),
      calories: _parseDouble(_caloriesCtrl),
      protein: _parseDouble(_proteinCtrl),
      carbs: _parseDouble(_carbsCtrl),
      fat: _parseDouble(_fatCtrl),
      fiber: _parseDouble(_fiberCtrl),
      sodium: _parseDouble(_sodiumCtrl),
      sugar: _parseDouble(_sugarCtrl),
      cholesterol: _parseDouble(_cholesterolCtrl),
      category: _category,
    );

    try {
      await FoodDatabaseService.instance.insertFood(food);
      if (!mounted) return;
      Navigator.pop(context, food);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Food Manually')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Food Name *',
                hintText: 'e.g. Max Protein Bar, Yoga Bar',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _servingSizeCtrl,
              decoration: const InputDecoration(
                labelText: 'Serving Size *',
                hintText: 'e.g. 1 bar (60g), 100g',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Serving size is required'
                  : null,
            ),
            const SizedBox(height: 12),
            // Searchable category picker
            InkWell(
              onTap: _pickCategory,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(_category),
              ),
            ),
            const SizedBox(height: 20),
            Text('Macros',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _NumberField(
                controller: _caloriesCtrl,
                label: 'Calories *',
                unit: 'kcal',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                      controller: _proteinCtrl, label: 'Protein', unit: 'g'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                      controller: _carbsCtrl, label: 'Carbs', unit: 'g'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                      controller: _fatCtrl, label: 'Fat', unit: 'g'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Additional Nutrients',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                      controller: _fiberCtrl, label: 'Fiber', unit: 'g'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                      controller: _sugarCtrl, label: 'Sugar', unit: 'g'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                      controller: _sodiumCtrl, label: 'Sodium', unit: 'mg'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                      controller: _cholesterolCtrl,
                      label: 'Cholesterol',
                      unit: 'mg'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Food'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Searchable Category Picker Dialog ───────────────────────────────────────

class _SearchableCategoryDialog extends StatefulWidget {
  const _SearchableCategoryDialog({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<_SearchableCategoryDialog> createState() =>
      _SearchableCategoryDialogState();
}

class _SearchableCategoryDialogState extends State<_SearchableCategoryDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.categories;
    final q = _query.toLowerCase();
    return widget.categories
        .where((c) => c.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420, maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search category...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No categories found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final cat = items[i];
                        final isSelected = cat == widget.selected;

                        return ListTile(
                          selected: isSelected,
                          title: Text(cat),
                          trailing: isSelected
                              ? Icon(Icons.check,
                                  color: theme.colorScheme.primary)
                              : null,
                          onTap: () {
                            widget.onSelected(cat);
                            Navigator.pop(context);
                          },
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

// ─── Number Field ────────────────────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.unit,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      validator: validator,
    );
  }
}
