import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/member_utils.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/event_template_model.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/group_provider.dart';

/// Widget for displaying and managing surprise party tasks
///
/// Features:
/// - Lists incomplete and completed tasks separately
/// - Tap to toggle completion status
/// - Long press to show task menu (edit, reassign, delete)
/// - Visual distinction between complete/incomplete
/// - Shows assignee with avatar and name
class SurprisePartyTaskList extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onAddTask;

  const SurprisePartyTaskList({
    super.key,
    required this.event,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final template = event.surprisePartyTemplate;

    if (template == null) {
      return const SizedBox.shrink();
    }

    final incompleteTasks = template.incompleteTasks;
    final completedTasks = template.tasks.where((t) => t.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Party Planning Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (onAddTask != null)
              TextButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Incomplete tasks
        if (incompleteTasks.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'INCOMPLETE',
            incompleteTasks.length,
            appColors,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...incompleteTasks.map((task) => _buildTaskItem(
                context,
                task,
                template,
                isComplete: false,
              )),
        ],

        // Completed tasks
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildSectionHeader(
            context,
            'COMPLETED',
            completedTasks.length,
            appColors,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...completedTasks.map((task) => _buildTaskItem(
                context,
                task,
                template,
                isComplete: true,
              )),
        ],

        // Empty state
        if (template.tasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.checklist,
                    size: 48,
                    color: appColors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No tasks yet',
                    style: TextStyle(
                      color: appColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap "Add" to create your first party planning task',
                    style: TextStyle(
                      color: appColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    AppColorsExtension appColors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        '$title ($count)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: appColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    SurprisePartyTask task,
    SurprisePartyTemplateModel template, {
    required bool isComplete,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return InkWell(
      onTap: () => _toggleTask(context, task),
      onLongPress: () => _showTaskMenu(context, task),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: appColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appColors.cardBorder),
        ),
        child: Row(
          children: [
            // Completion icon
            Icon(
              isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isComplete ? appColors.success : appColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),

            // Task details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration:
                          isComplete ? TextDecoration.lineThrough : null,
                      color: isComplete
                          ? appColors.textMuted
                          : colorScheme.onSurface,
                    ),
                  ),

                  // Assignee
                  if (task.assignedTo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Consumer<GroupProvider>(
                        builder: (context, groupProvider, _) {
                          final assignee = groupProvider.selectedGroupMembers
                              .where((m) => m.userId == task.assignedTo)
                              .firstOrNull;

                          return Row(
                            children: [
                              if (assignee != null) ...[
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor:
                                      MemberUtils.getColorById(assignee.userId),
                                  child: Text(
                                    MemberUtils.getInitials(assignee.displayName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  assignee.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: appColors.textSecondary,
                                  ),
                                ),
                              ] else
                                Text(
                                  'Assigned',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: appColors.textSecondary,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Not assigned',
                        style: TextStyle(
                          fontSize: 13,
                          color: appColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // More menu icon
            Icon(
              Icons.more_vert,
              color: appColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTask(BuildContext context, SurprisePartyTask task) {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    calendarProvider.toggleSurprisePartyTask(event.id, task.id);
  }

  void _showTaskMenu(BuildContext context, SurprisePartyTask task) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Center(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: appColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Divider(color: appColors.divider, height: 1),

                // Menu options
                ListTile(
                  leading: Icon(
                    task.isCompleted
                        ? Icons.radio_button_unchecked
                        : Icons.check_circle,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                      task.isCompleted ? 'Mark incomplete' : 'Mark complete'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleTask(context, task);
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person, color: colorScheme.primary),
                  title: Text(
                      task.assignedTo != null ? 'Reassign' : 'Assign to someone'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAssigneeSelector(context, task);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete task',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteTask(context, task);
                  },
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAssigneeSelector(BuildContext context, SurprisePartyTask task) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Consumer<GroupProvider>(
              builder: (context, groupProvider, _) {
                final members = groupProvider.selectedGroupMembers;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Assign to...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: appColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: appColors.divider, height: 1),

                    // Unassign option
                    if (task.assignedTo != null)
                      ListTile(
                        leading: Icon(Icons.person_off,
                            color: appColors.textSecondary),
                        title: const Text('Unassign'),
                        onTap: () {
                          Navigator.pop(context);
                          _assignTask(context, task, null);
                        },
                      ),

                    // Member list
                    ...members.map((member) {
                      final isAssigned = task.assignedTo == member.userId;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: MemberUtils.getColorById(member.userId),
                          child: Text(
                            MemberUtils.getInitials(member.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(member.displayName),
                        trailing: isAssigned
                            ? Icon(Icons.check, color: colorScheme.primary)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _assignTask(context, task, member.userId);
                        },
                      );
                    }),

                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _assignTask(BuildContext context, SurprisePartyTask task, String? userId) {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    calendarProvider.assignSurprisePartyTask(event.id, task.id, userId);
  }

  void _deleteTask(BuildContext context, SurprisePartyTask task) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final calendarProvider =
                  Provider.of<CalendarProvider>(context, listen: false);
              calendarProvider.deleteSurprisePartyTask(event.id, task.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
