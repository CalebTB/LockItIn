import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/event_template_model.dart';
import '../../providers/calendar_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modal bottom sheet for adding a new potluck dish
///
/// Features:
/// - Text input for dish name and description
/// - Category selector (mains, sides, desserts, drinks, appetizers)
/// - Optional serving size input
/// - Dietary info checkboxes (vegetarian, vegan, gluten-free, dairy-free, nut-free)
/// - Two submit options:
///   - "Add Dish" (unclaimed, available for others)
///   - "Add & Claim for Myself" (auto-claimed by current user)
/// - Form validation
/// - Keyboard handling
///
/// **Pattern**: Follows AddTaskSheet structure
class AddPotluckDishSheet extends StatefulWidget {
  final EventModel event;

  const AddPotluckDishSheet({
    super.key,
    required this.event,
  });

  @override
  State<AddPotluckDishSheet> createState() => _AddPotluckDishSheetState();
}

class _AddPotluckDishSheetState extends State<AddPotluckDishSheet> {
  final _dishNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servingSizeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'mains'; // Default category
  final List<String> _selectedDietaryInfo = [];
  bool _isSubmitting = false;

  // Available dietary options
  static const List<String> _dietaryOptions = [
    'vegetarian',
    'vegan',
    'gluten-free',
    'dairy-free',
    'nut-free',
  ];

  @override
  void dispose() {
    _dishNameController.dispose();
    _descriptionController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Add Dish',
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

                  const SizedBox(height: AppSpacing.lg),

                  // Dish name input
                  _buildTextField(
                    controller: _dishNameController,
                    label: 'Dish Name *',
                    hint: 'e.g., Mac and Cheese',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Dish name is required';
                      }
                      return null;
                    },
                    appColors: appColors,
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Category selector
                  _buildCategorySelector(appColors, colorScheme),

                  const SizedBox(height: AppSpacing.md),

                  // Description input
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description (Optional)',
                    hint: 'Add any special notes or ingredients',
                    maxLines: 2,
                    appColors: appColors,
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Serving size input
                  _buildTextField(
                    controller: _servingSizeController,
                    label: 'Serving Size (Optional)',
                    hint: 'e.g., Serves 8-10',
                    appColors: appColors,
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Dietary info checkboxes
                  _buildDietaryInfoSection(appColors, colorScheme),

                  const SizedBox(height: AppSpacing.xl),

                  // Action buttons
                  _buildActionButtons(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    required AppColorsExtension appColors,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: appColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: appColors.textMuted),
            filled: true,
            fillColor: appColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: appColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: appColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: appColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Chip-based category selector
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: PotluckTemplateModel.standardCategories.map((category) {
            final isSelected = _selectedCategory == category;
            final categoryIcon = _getCategoryIcon(category);

            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(categoryIcon),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_capitalize(category)),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
              backgroundColor: appColors.cardBackground,
              selectedColor: colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: colorScheme.primary,
              side: BorderSide(
                color: isSelected ? colorScheme.primary : appColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : appColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDietaryInfoSection(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIETARY INFO (OPTIONAL)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: appColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Checkboxes for dietary info
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: _dietaryOptions.map((option) {
            final isSelected = _selectedDietaryInfo.contains(option);

            return FilterChip(
              label: Text(_capitalize(option)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDietaryInfo.add(option);
                  } else {
                    _selectedDietaryInfo.remove(option);
                  }
                });
              },
              backgroundColor: appColors.cardBackground,
              selectedColor: appColors.success.withValues(alpha: 0.2),
              checkmarkColor: appColors.success,
              side: BorderSide(
                color: isSelected ? appColors.success : appColors.cardBorder,
              ),
              labelStyle: TextStyle(
                color: isSelected ? appColors.success : appColors.textSecondary,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Column(
      children: [
        // Add & Claim button (primary action)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _handleSubmit(autoClaimBool: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Add & Claim for Myself',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Add (unclaimed) button (secondary action)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => _handleSubmit(autoClaimBool: false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Add Dish (Unclaimed)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit({required bool autoClaimBool}) async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = Provider.of<CalendarProvider>(context, listen: false);
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      // Add dish to template
      await provider.addPotluckDish(
        eventId: widget.event.id,
        category: _selectedCategory,
        dishName: _dishNameController.text.trim(),
        userId: autoClaimBool ? currentUserId : null,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        servingSize: _servingSizeController.text.trim().isEmpty
            ? null
            : _servingSizeController.text.trim(),
        dietaryInfo: _selectedDietaryInfo,
      );

      // Close sheet on success
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              autoClaimBool
                  ? 'Dish added and claimed!'
                  : 'Dish added successfully',
            ),
            backgroundColor: context.appColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add dish: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'mains':
        return '🍗';
      case 'sides':
        return '🥗';
      case 'desserts':
        return '🍰';
      case 'drinks':
        return '🥤';
      case 'appetizers':
        return '🧀';
      default:
        return '🍽️';
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
