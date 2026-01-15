import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/member_utils.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/event_template_model.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/group_provider.dart';

/// Modal bottom sheet for adding a new surprise party task
///
/// Features:
/// - Text input for task title
/// - Optional assignee selection from group members
/// - Form validation
/// - Keyboard handling
class AddTaskSheet extends StatefulWidget {
  final EventModel event;

  const AddTaskSheet({
    super.key,
    required this.event,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _taskTitleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedAssigneeId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _taskTitleController.dispose();
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
                          'Add Task',
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

                // Task title input
                Text(
                  'TASK TITLE *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _taskTitleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Buy decorations',
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
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSubmit(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Assignee selection
                _buildAssigneeSection(appColors, colorScheme),

                const SizedBox(height: AppSpacing.xl),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      disabledBackgroundColor: appColors.textDisabled,
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
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            'Add Task',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneeSection(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        final members = groupProvider.selectedGroupMembers;

        // Filter out the guest of honor (target)
        final template = widget.event.surprisePartyTemplate;
        final availableMembers = template != null && template.guestOfHonorId != null
            ? members.where((m) => m.userId != template.guestOfHonorId).toList()
            : members;

        if (availableMembers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ASSIGN TO (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // "No one" option
            InkWell(
              onTap: () {
                setState(() {
                  _selectedAssigneeId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _selectedAssigneeId == null
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : appColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedAssigneeId == null
                        ? colorScheme.primary
                        : appColors.cardBorder,
                    width: _selectedAssigneeId == null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedAssigneeId == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selectedAssigneeId == null
                          ? colorScheme.primary
                          : appColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Not assigned',
                      style: TextStyle(
                        fontWeight:
                            _selectedAssigneeId == null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Group members
            ...availableMembers.map((member) {
              final isSelected = _selectedAssigneeId == member.userId;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedAssigneeId = member.userId;
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
                      color: isSelected ? colorScheme.primary : appColors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? colorScheme.primary : appColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: MemberUtils.getColorById(member.userId),
                        child: Text(
                          MemberUtils.getInitials(member.displayName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Name
                      Text(
                        member.displayName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      final template = widget.event.surprisePartyTemplate;

      if (template == null) {
        _showError('Event does not have a surprise party template');
        return;
      }

      // Add task to template
      final updatedTemplate = template.addTask(
        title: _taskTitleController.text.trim(),
        assignedTo: _selectedAssigneeId,
      );

      // Update event with new template
      final updatedEvent = widget.event.copyWith(
        templateData: updatedTemplate,
      );

      // Update via CalendarProvider (handles Supabase sync)
      calendarProvider.updateEvent(widget.event, updatedEvent);

      // Close sheet
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to add task: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
