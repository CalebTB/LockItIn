import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/event_template_model.dart';

/// Modal bottom sheet for configuring potluck template settings
///
/// Allows user to:
/// - Set max dishes per person (1, 2, 3, or unlimited)
/// - Enable/disable duplicate dishes
/// - Optionally pre-fill with suggested dishes
///
/// Returns a configured [PotluckTemplateModel] via Navigator.pop()
///
/// **Pattern**: Follows SurprisePartyConfigSheet structure
/// - DraggableScrollableSheet with initialChildSize: 0.9
/// - Fixed header + scrollable content + sticky footer
/// - Theme-based colors (NEVER hardcoded)
class PotluckConfigSheet extends StatefulWidget {
  final PotluckTemplateModel? existingTemplate;

  const PotluckConfigSheet({
    super.key,
    this.existingTemplate,
  });

  @override
  State<PotluckConfigSheet> createState() => _PotluckConfigSheetState();
}

class _PotluckConfigSheetState extends State<PotluckConfigSheet> {
  int _maxDishesPerPerson = 2; // Default: 2 dishes
  bool _allowDuplicates = true; // Default: allow duplicates
  bool _preFillDishes = true; // Default: pre-fill 5 suggested dishes

  @override
  void initState() {
    super.initState();

    // Pre-fill if editing existing template
    if (widget.existingTemplate != null) {
      _maxDishesPerPerson = widget.existingTemplate!.maxDishesPerPerson;
      _allowDuplicates = widget.existingTemplate!.allowDuplicates;
      _preFillDishes = false; // Don't re-add dishes if editing
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(context, colorScheme, appColors),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _buildMaxDishesSection(appColors, colorScheme),
                    const SizedBox(height: AppSpacing.xl),
                    _buildDuplicatesSection(appColors, colorScheme),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPreFillSection(appColors, colorScheme),
                  ],
                ),
              ),
              _buildContinueButton(colorScheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, ColorScheme colorScheme, AppColorsExtension appColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: appColors.divider),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Center(
              child: Text(
                'Configure Potluck',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: appColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMaxDishesSection(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MAX DISHES PER PERSON',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: appColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Limit how many dishes each person can bring',
          style: TextStyle(
            fontSize: 14,
            color: appColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Options: 1, 2, 3, Unlimited
        ...[
          (1, '1 dish'),
          (2, '2 dishes'),
          (3, '3 dishes'),
          (0, 'Unlimited'),
        ].map((option) {
          final value = option.$1;
          final label = option.$2;
          final isSelected = _maxDishesPerPerson == value;

          return InkWell(
            onTap: () {
              setState(() {
                _maxDishesPerPerson = value;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : appColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : appColors.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? colorScheme.primary
                        : appColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onSurface
                          : appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDuplicatesSection(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allow duplicate dishes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Multiple people can bring the same dish',
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _allowDuplicates,
            onChanged: (value) {
              setState(() {
                _allowDuplicates = value;
              });
            },
            activeTrackColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPreFillSection(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pre-fill suggested dishes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Add 5 common potluck dishes to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _preFillDishes,
            onChanged: (value) {
              setState(() {
                _preFillDishes = value;
              });
            },
            activeTrackColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: context.appColors.divider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    // Build initial dishes list (pre-fill if enabled)
    final List<PotluckDish> initialDishes = _preFillDishes
        ? _buildPreFilledDishes()
        : widget.existingTemplate?.dishes ?? [];

    // Create configured template
    final template = PotluckTemplateModel(
      maxDishesPerPerson: _maxDishesPerPerson,
      allowDuplicates: _allowDuplicates,
      dishes: initialDishes,
    );

    // Return template to caller
    Navigator.pop(context, template);
  }

  /// Generate 5 pre-filled dishes across all categories
  List<PotluckDish> _buildPreFilledDishes() {
    const uuid = Uuid();

    return [
      PotluckDish(
        id: uuid.v4(),
        category: 'mains',
        dishName: 'Turkey',
        servingSize: 'Serves 10-12',
      ),
      PotluckDish(
        id: uuid.v4(),
        category: 'sides',
        dishName: 'Mashed Potatoes',
        servingSize: 'Serves 8',
      ),
      PotluckDish(
        id: uuid.v4(),
        category: 'sides',
        dishName: 'Green Bean Casserole',
        servingSize: 'Serves 8',
      ),
      PotluckDish(
        id: uuid.v4(),
        category: 'desserts',
        dishName: 'Pumpkin Pie',
        servingSize: '2 pies',
      ),
      PotluckDish(
        id: uuid.v4(),
        category: 'drinks',
        dishName: 'Apple Cider',
        servingSize: '1 gallon',
      ),
    ];
  }
}
