import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/currency_service.dart';
import '../../data/unit_converter.dart';

const _categoryIcons = <String, IconData>{
  'Currency': Icons.attach_money,
  'Length': Icons.straighten,
  'Area': Icons.crop_square,
  'Volume': Icons.local_drink,
  'Weight': Icons.fitness_center,
  'Temperature': Icons.thermostat,
  'Speed': Icons.speed,
  'Time': Icons.timer,
  'Data': Icons.storage,
  'Energy': Icons.bolt,
  'Pressure': Icons.compress,
  'Power': Icons.power,
  'Angle': Icons.rotate_right,
  'Fuel': Icons.local_gas_station,
  'Force': Icons.engineering,
};

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, this.initialCategory});

  /// If set, shows converter directly for this category index with its own Scaffold.
  final int? initialCategory;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  int _selectedCategory = 0;
  late int _fromIndex;
  late int _toIndex;
  String _input = '1';
  String _result = '';
  final _inputController = TextEditingController(text: '1');

  // Currency live rates
  List<UnitDef>? _liveCurrencyUnits;
  bool _loadingRates = false;
  String? _ratesError;
  Timer? _refreshTimer;

  // Whether to show the converter or the category grid
  bool _showConverter = false;

  bool get _isStandalone => widget.initialCategory != null;

  @override
  void initState() {
    super.initState();
    _fromIndex = 0;
    _toIndex = 1;
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
      _showConverter = true;
      if (_isCurrencyTab) {
        _fetchCurrencyRates();
        _startAutoRefresh();
      } else {
        _convert();
      }
    }
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategory = index;
      _fromIndex = 0;
      _toIndex = 1;
      _ratesError = null;
      _showConverter = true;
    });
    if (_isCurrencyTab) {
      _fetchCurrencyRates();
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
      _convert();
    }
  }

  void _backToGrid() {
    _stopAutoRefresh();
    setState(() => _showConverter = false);
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isCurrencyTab && mounted) {
        _fetchCurrencyRates(forceRefresh: true);
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  bool get _isCurrencyTab => categories[_selectedCategory].name == 'Currency';

  List<UnitDef> get _units {
    if (_isCurrencyTab && _liveCurrencyUnits != null) {
      return _liveCurrencyUnits!;
    }
    return categories[_selectedCategory].units;
  }

  Future<void> _fetchCurrencyRates({bool forceRefresh = false}) async {
    final service = CurrencyService.instance;

    if (service.hasCachedRates) {
      _liveCurrencyUnits = service.cachedUnits;
      _convert();
    }

    setState(() => _loadingRates = true);
    try {
      final units = await service.fetchRates(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _liveCurrencyUnits = units;
        _loadingRates = false;
        _convert();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRates = false;
        if (_liveCurrencyUnits == null) {
          _ratesError = 'Could not fetch live rates. Using fallback.';
        }
        _convert();
      });
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    final value = double.tryParse(_input);
    if (value == null) {
      _result = '';
      return;
    }
    final units = _units;
    if (_fromIndex >= units.length || _toIndex >= units.length) {
      _result = '';
      return;
    }
    final r = convert(value, units[_fromIndex], units[_toIndex]);
    if (r == r.truncateToDouble() && r.abs() < 1e15) {
      _result = r.toInt().toString();
    } else {
      _result = r
          .toStringAsFixed(10)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
  }

  String _ratesDateLabel() {
    final dt = CurrencyService.instance.ratesUpdateTime;
    if (dt != null) {
      final dateStr = DateFormat('MMM d, yyyy').format(dt);
      final now = DateFormat('h:mm:ss a').format(DateTime.now());
      return 'Rates for $dateStr \u2022 Updated $now';
    }
    return 'Live currency rates';
  }

  void _swap() {
    setState(() {
      final tmp = _fromIndex;
      _fromIndex = _toIndex;
      _toIndex = tmp;
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: Text(categories[_selectedCategory].name),
        ),
        body: _buildConverterBody(context),
      );
    }
    if (_showConverter) {
      return _buildConverter(context);
    }
    return _buildCategoryGrid(context);
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final icon = _categoryIcons[cat.name] ?? Icons.swap_horiz;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _selectCategory(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Converter form content (reused by standalone and embedded modes).
  Widget _buildConverterBody(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (_isCurrencyTab && _loadingRates)
          const LinearProgressIndicator(),
        if (_ratesError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _ratesError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: _buildConverterForm(context),
        ),
      ],
    );
  }

  Widget _buildConverter(BuildContext context) {
    final theme = Theme.of(context);
    final catName = categories[_selectedCategory].name;

    return Column(
      children: [
        // Header with back button and category name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToGrid,
              ),
              const SizedBox(width: 4),
              Icon(
                _categoryIcons[catName] ?? Icons.swap_horiz,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                catName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildConverterBody(context)),
      ],
    );
  }

  Widget _buildConverterForm(BuildContext context) {
    final theme = Theme.of(context);
    final units = _units;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _UnitField(
            label: 'From',
            units: units,
            selectedIndex: _fromIndex,
            onUnitChanged: (i) => setState(() {
              _fromIndex = i;
              _convert();
            }),
            controller: _inputController,
            onValueChanged: (v) => setState(() {
              _input = v;
              _convert();
            }),
            readOnly: false,
          ),
          const SizedBox(height: 8),
          IconButton.filled(
            onPressed: _swap,
            icon: const Icon(Icons.swap_vert),
          ),
          const SizedBox(height: 8),
          _UnitField(
            label: 'To',
            units: units,
            selectedIndex: _toIndex,
            onUnitChanged: (i) => setState(() {
              _toIndex = i;
              _convert();
            }),
            value: _result,
            readOnly: true,
          ),
          const SizedBox(height: 24),
          if (_input.isNotEmpty && _result.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conversion',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_input ${units[_fromIndex].symbol} = $_result ${units[_toIndex].symbol}',
                      style: theme.textTheme.titleLarge,
                    ),
                    if (_isCurrencyTab && _liveCurrencyUnits != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _ratesDateLabel(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({
    required this.label,
    required this.units,
    required this.selectedIndex,
    required this.onUnitChanged,
    required this.readOnly,
    this.controller,
    this.onValueChanged,
    this.value,
  });

  final String label;
  final List<UnitDef> units;
  final int selectedIndex;
  final ValueChanged<int> onUnitChanged;
  final bool readOnly;
  final TextEditingController? controller;
  final ValueChanged<String>? onValueChanged;
  final String? value;

  void _showUnitPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _UnitPickerDialog(
        units: units,
        selectedIndex: selectedIndex,
        onSelected: onUnitChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = units[selectedIndex];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: readOnly
                      ? Text(
                          value ?? '',
                          style: theme.textTheme.headlineSmall,
                        )
                      : TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          style: theme.textTheme.headlineSmall,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: onValueChanged,
                        ),
                ),
                const SizedBox(width: 8),
                Text(
                  unit.symbol,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showUnitPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${unit.name} (${unit.symbol})',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitPickerDialog extends StatefulWidget {
  const _UnitPickerDialog({
    required this.units,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<UnitDef> units;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_UnitPickerDialog> createState() => _UnitPickerDialogState();
}

class _UnitPickerDialogState extends State<_UnitPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> get _filteredIndices {
    if (_query.isEmpty) {
      return List.generate(widget.units.length, (i) => i);
    }
    final q = _query.toLowerCase();
    return [
      for (int i = 0; i < widget.units.length; i++)
        if (widget.units[i].name.toLowerCase().contains(q) ||
            widget.units[i].symbol.toLowerCase().contains(q))
          i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indices = _filteredIndices;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search units...',
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
              child: indices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No units found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: indices.length,
                      itemBuilder: (context, i) {
                        final idx = indices[i];
                        final unit = widget.units[idx];
                        final isSelected = idx == widget.selectedIndex;

                        return ListTile(
                          selected: isSelected,
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            child: Text(
                              unit.symbol,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          title: Text(unit.name),
                          subtitle: Text(unit.symbol),
                          trailing: isSelected
                              ? Icon(Icons.check,
                                  color: theme.colorScheme.primary)
                              : null,
                          onTap: () {
                            widget.onSelected(idx);
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