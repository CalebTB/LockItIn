import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/member_utils.dart';
import '../../../data/models/event_template_model.dart';
import '../../providers/group_provider.dart';

/// Modal bottom sheet for configuring surprise party template settings
///
/// Allows user to:
/// - Select the guest of honor (surprise target)
/// - Enter a decoy event title
/// - Set optional auto-reveal time
/// - Choose who is "in on it" (all group members except target, or specific coordinators)
///
/// Returns a configured [SurprisePartyTemplateModel] via Navigator.pop()
///
/// **Note:** Task management happens AFTER the event is created, via the
/// SurprisePartyDashboard screen. This sheet only handles initial configuration.
class SurprisePartyConfigSheet extends StatefulWidget {
  final String groupId;
  final SurprisePartyTemplateModel? existingTemplate;

  const SurprisePartyConfigSheet({
    super.key,
    required this.groupId,
    this.existingTemplate,
  });

  @override
  State<SurprisePartyConfigSheet> createState() =>
      _SurprisePartyConfigSheetState();
}

class _SurprisePartyConfigSheetState
    extends State<SurprisePartyConfigSheet> {
  String? _selectedTargetUserId;
  final _decoyTitleController = TextEditingController();
  DateTime? _revealAt;
  CoordinatorSelection _coordinatorSelection =
      CoordinatorSelection.allExceptTarget;
  final List<String> _selectedCoordinatorIds = [];

  @override
  void initState() {
    super.initState();

    // Load group members
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.selectGroup(widget.groupId);
    });

    // Pre-fill if editing existing template
    if (widget.existingTemplate != null) {
      _selectedTargetUserId = widget.existingTemplate!.guestOfHonorId;
      _decoyTitleController.text =
          widget.existingTemplate!.decoyTitle ?? '';
      _revealAt = widget.existingTemplate!.revealAt;
      _selectedCoordinatorIds.addAll(widget.existingTemplate!.inOnItUserIds);

      if (_selectedCoordinatorIds.isNotEmpty) {
        _coordinatorSelection = CoordinatorSelection.specific;
      }
    }
  }

  @override
  void dispose() {
    _decoyTitleController.dispose();
    super.dispose();
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
                    _buildTargetUserSection(appColors, colorScheme),
                    const SizedBox(height: AppSpacing.xl),
                    _buildDecoyEventSection(appColors, colorScheme),
                    const SizedBox(height: AppSpacing.xl),
                    _buildRevealTimeSection(appColors, colorScheme),
                    const SizedBox(height: AppSpacing.xl),
                    _buildCoordinatorSection(appColors, colorScheme),
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
                'Configure Surprise Party',
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

  Widget _buildTargetUserSection(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        if (groupProvider.isLoadingMembers) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = groupProvider.selectedGroupMembers;

        if (members.isEmpty) {
          return const Center(child: Text('No group members found'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHO\'S THE SURPRISE FOR? *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Group members list
            ...members.map((member) {
              final isSelected = _selectedTargetUserId == member.userId;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTargetUserId = member.userId;
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
                      // Avatar
                      CircleAvatar(
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
                      const SizedBox(width: AppSpacing.md),

                      // Name
                      Expanded(
                        child: Text(
                          member.displayName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),

                      // Selection indicator
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
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

  Widget _buildDecoyEventSection(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DECOY EVENT (WHAT THEY\'LL SEE) *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: appColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _decoyTitleController,
          decoration: InputDecoration(
            hintText: 'Team Lunch',
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
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Warning callout
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade900),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _selectedTargetUserId != null
                      ? '${_getSelectedTargetName()} will see "${_decoyTitleController.text.isNotEmpty ? _decoyTitleController.text : "this title"}" on their calendar instead of the real event title.'
                      : 'The target will see this title on their calendar instead of the real event title.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevealTimeSection(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTO-REVEAL DATE (OPTIONAL)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: appColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: () => _selectRevealTime(context),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: appColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: appColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: appColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _revealAt != null
                        ? _formatDateTime(_revealAt!)
                        : 'Select date and time',
                    style: TextStyle(
                      color: _revealAt != null
                          ? colorScheme.onSurface
                          : appColors.textMuted,
                    ),
                  ),
                ),
                if (_revealAt != null)
                  IconButton(
                    icon: Icon(Icons.clear, color: appColors.textMuted),
                    onPressed: () => setState(() => _revealAt = null),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 16, color: appColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Event will automatically reveal to the target at this time.',
                style: TextStyle(
                  fontSize: 12,
                  color: appColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoordinatorSection(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        final members = groupProvider.selectedGroupMembers;

        if (members.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHO KNOWS ABOUT THE SURPRISE?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // All except target (recommended)
            InkWell(
              onTap: () {
                setState(() {
                  _coordinatorSelection = CoordinatorSelection.allExceptTarget;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _coordinatorSelection ==
                          CoordinatorSelection.allExceptTarget
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : appColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _coordinatorSelection ==
                            CoordinatorSelection.allExceptTarget
                        ? colorScheme.primary
                        : appColors.cardBorder,
                    width: _coordinatorSelection ==
                            CoordinatorSelection.allExceptTarget
                        ? 2
                        : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _coordinatorSelection ==
                              CoordinatorSelection.allExceptTarget
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _coordinatorSelection ==
                              CoordinatorSelection.allExceptTarget
                          ? colorScheme.primary
                          : appColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All group members except target',
                            style: TextStyle(
                              fontWeight: _coordinatorSelection ==
                                      CoordinatorSelection.allExceptTarget
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            _selectedTargetUserId != null
                                ? 'Everyone except ${_getSelectedTargetName()} will be in on it'
                                : 'Everyone except the target will be in on it',
                            style: TextStyle(
                              fontSize: 12,
                              color: appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Select specific coordinators
            InkWell(
              onTap: () {
                setState(() {
                  _coordinatorSelection = CoordinatorSelection.specific;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _coordinatorSelection == CoordinatorSelection.specific
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : appColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _coordinatorSelection == CoordinatorSelection.specific
                            ? colorScheme.primary
                            : appColors.cardBorder,
                    width:
                        _coordinatorSelection == CoordinatorSelection.specific
                            ? 2
                            : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _coordinatorSelection == CoordinatorSelection.specific
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color:
                          _coordinatorSelection == CoordinatorSelection.specific
                              ? colorScheme.primary
                              : appColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text('Select specific coordinators'),
                    ),
                  ],
                ),
              ),
            ),

            // Show member selection if specific is chosen
            if (_coordinatorSelection == CoordinatorSelection.specific) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'SELECT COORDINATORS:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: appColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...members
                  .where((m) => m.userId != _selectedTargetUserId)
                  .map((member) {
                final isSelected = _selectedCoordinatorIds.contains(member.userId);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedCoordinatorIds.add(member.userId);
                      } else {
                        _selectedCoordinatorIds.remove(member.userId);
                      }
                    });
                  },
                  title: Text(member.displayName),
                  secondary: CircleAvatar(
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
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildContinueButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            padding:
                const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Confirm Settings',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    // Validation
    if (_selectedTargetUserId == null) {
      _showError('Please select who the surprise is for');
      return;
    }

    if (_decoyTitleController.text.trim().isEmpty) {
      _showError('Please enter a decoy event title');
      return;
    }

    // Get coordinator IDs based on selection
    final coordinatorIds = _getCoordinatorIds();

    // Create template model with initial configuration
    // Tasks are added later via SurprisePartyDashboard after event creation
    final template = SurprisePartyTemplateModel(
      guestOfHonorId: _selectedTargetUserId,
      decoyTitle: _decoyTitleController.text.trim(),
      revealAt: _revealAt,
      tasks: const [], // Empty initially - coordinators add tasks in dashboard
      inOnItUserIds: coordinatorIds,
    );

    // Return configured template to calling screen
    Navigator.pop(context, template);
  }

  List<String> _getCoordinatorIds() {
    if (_coordinatorSelection == CoordinatorSelection.allExceptTarget) {
      // Get all group members except target
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      return groupProvider.selectedGroupMembers
          .where((m) => m.userId != _selectedTargetUserId)
          .map((m) => m.userId)
          .toList();
    } else {
      return _selectedCoordinatorIds;
    }
  }

  Future<void> _selectRevealTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _revealAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(_revealAt ?? DateTime.now().add(const Duration(hours: 1))),
    );

    if (time == null || !mounted) return;

    setState(() {
      _revealAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _getSelectedTargetName() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final target = groupProvider.selectedGroupMembers
        .where((m) => m.userId == _selectedTargetUserId)
        .firstOrNull;
    return target?.displayName ?? 'Target';
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

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$month $day, $year at $displayHour:$minute $period';
  }
}

enum CoordinatorSelection {
  allExceptTarget,
  specific,
}
