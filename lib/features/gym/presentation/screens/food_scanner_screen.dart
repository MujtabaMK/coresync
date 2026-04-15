import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/gemini_food_service.dart';
import '../../domain/food_scan_model.dart';
import '../providers/gym_provider.dart';
import '../widgets/food_scan_result_sheet.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  final _picker = ImagePicker();
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    context.read<GymCubit>().loadFoodScans();
  }

  Future<void> _scanFood(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final bytes = await picked.readAsBytes();
      final items = await GeminiFoodService.instance.analyzeFoodImage(bytes);

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No food items detected. Try again.')),
        );
        return;
      }

      _showResultSheet(items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showResultSheet(List<FoodItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodScanResultSheet(
        foodItems: items,
        onSave: (scan) {
          context.read<GymCubit>().saveFoodScan(scan);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food scan saved!')),
          );
        },
        onRetake: () {
          Navigator.pop(context);
          _showSourcePicker();
        },
      ),
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _scanFood(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _scanFood(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GymCubit, GymState>(
      builder: (context, state) {
        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Daily summary card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _DailySummaryCard(
                      totalCalories: state.dailyCalories,
                      scans: state.foodScans,
                    ),
                  ),
                ),
                // Today's scans header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Today's Meals",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Scans list
                if (state.foodScans.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_rounded,
                              size: 64,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No meals scanned today',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to scan your food',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.builder(
                      itemCount: state.foodScans.length,
                      itemBuilder: (context, index) {
                        final scan = state.foodScans[index];
                        return Dismissible(
                          key: Key(scan.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete,
                                color: Colors.white),
                          ),
                          onDismissed: (_) {
                            context.read<GymCubit>().deleteFoodScan(scan.id);
                          },
                          child: _ScanCard(scan: scan),
                        );
                      },
                    ),
                  ),
                // Bottom padding for FAB
                const SliverToBoxAdapter(
                    child: SizedBox(height: 80)),
              ],
            ),
            // Loading overlay
            if (_isAnalyzing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing your food...',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            // FAB
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _isAnalyzing ? null : _showSourcePicker,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Food'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({
    required this.totalCalories,
    required this.scans,
  });

  final double totalCalories;
  final List<FoodScanModel> scans;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double totalProtein = 0, totalCarbs = 0, totalFat = 0;
    for (final scan in scans) {
      for (final item in scan.foodItems) {
        totalProtein += item.protein * item.quantity;
        totalCarbs += item.carbs * item.quantity;
        totalFat += item.fat * item.quantity;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Today\'s Calories',
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            Text(
              '${totalCalories.round()}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text('kcal',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MacroColumn(
                    label: 'Protein',
                    value: '${totalProtein.toStringAsFixed(1)}g',
                    color: Colors.blue),
                _MacroColumn(
                    label: 'Carbs',
                    value: '${totalCarbs.toStringAsFixed(1)}g',
                    color: Colors.orange),
                _MacroColumn(
                    label: 'Fat',
                    value: '${totalFat.toStringAsFixed(1)}g',
                    color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  const _MacroColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
      ],
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.scan});

  final FoodScanModel scan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat.jm().format(scan.scannedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(timeStr, style: theme.textTheme.bodySmall),
                  ],
                ),
                Text(
                  '${scan.totalCalories.round()} kcal',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...scan.foodItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.quantity > 1
                            ? '${item.name} x${item.quantity}'
                            : item.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${(item.calories * item.quantity).round()} kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                    ),
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
