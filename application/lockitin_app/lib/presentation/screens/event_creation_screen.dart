import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../data/models/event_template_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_date_time_picker.dart';
import '../widgets/adaptive_text_field.dart';
import 'group_proposal_wizard.dart';
import '../../core/utils/timezone_utils.dart';
import '../../core/utils/logger.dart';

/// Event creation mode enum for dual-context support
///
/// Personal events: Simple form, quick save to personal calendar
/// Group proposals: Wizard flow with time options + voting
enum EventCreationMode {
  personalEvent,      // Simple form, no group features
  groupProposal,      // Advanced form with time options + voting
  editPersonalEvent,  // Edit existing personal event
  editGroupProposal,  // Edit existing group proposal
}

/// Event creation/editing screen with progressive disclosure form
///
/// Redesigned for better UX with:
/// - Dual-mode support (personal events vs group proposals)
/// - Privacy promoted to field 2 (core differentiator)
/// - Progressive disclosure (5 required fields, optional collapsed)
/// - Bottom CTA button (large, prominent, sticky)
/// - Template chips for quick event creation
/// - Grouped date/time card
class EventCreationScreen extends StatefulWidget {
  final EventCreationMode mode;
  final DateTime? initialDate;
  final EventModel? eventToEdit;
  final String? groupId;           // Group context for proposals
  final String? groupName;         // Group name for display
  final int? groupMemberCount;     // Number of members in the group

  const EventCreationScreen({
    super.key,
    this.mode = EventCreationMode.personalEvent,
    this.initialDate,
    this.eventToEdit,
    this.groupId,
    this.groupName,
    this.groupMemberCount,
  });

  /// Check if this screen is in edit mode
  bool get isEditMode => mode == EventCreationMode.editPersonalEvent ||
                         mode == EventCreationMode.editGroupProposal;

  /// Check if this screen is in group proposal mode
  bool get isProposalMode => mode == EventCreationMode.groupProposal ||
                             mode == EventCreationMode.editGroupProposal;

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

/// Event templates for quick creation
enum EventTemplate {
  party,
  dinner,
  movieNight,
  surpriseParty,
  friendsgiving,
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  EventVisibility _visibility = EventVisibility.sharedWithName;
  EventCategory _category = EventCategory.other;
  String _emoji = '🎯';
  bool _isAllDay = false;
  bool _showMoreOptions = false;
  EventTemplate? _selectedTemplate;
  EventTemplateModel? _templateData; // Template data (surprise_party, potluck, etc.)
  bool _showPrivacyTooltip = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTimePrivacyPicker();

    if (widget.eventToEdit != null) {
      // Edit mode: pre-fill form with existing event data
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _locationController.text = event.location ?? '';
      _notesController.text = event.description ?? '';
      _startDate = event.startTime;
      _endDate = event.endTime;
      _startTime = TimeOfDay.fromDateTime(event.startTime);
      _endTime = TimeOfDay.fromDateTime(event.endTime);
      _visibility = event.visibility;
      _category = event.category;
      _emoji = event.emoji ?? _getDefaultEmoji(event.category);
      _isAllDay = event.startTime.hour == 0 &&
                  event.startTime.minute == 0 &&
                  event.endTime.hour == 23 &&
                  event.endTime.minute == 59;
      // Show more options if optional fields are filled
      _showMoreOptions = _notesController.text.isNotEmpty;
    } else {
      // Create mode: use defaults
      _startDate = widget.initialDate ?? DateTime.now();
      _endDate = _startDate;
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);

      // Load per-group privacy default if creating event for a group
      if (widget.groupId != null) {
        _loadGroupPrivacyDefault();
      }
    }
  }

  /// Load and apply the saved privacy default for the current group
  Future<void> _loadGroupPrivacyDefault() async {
    if (widget.groupId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'privacy_default_${widget.groupId}';
    final savedValue = prefs.getString(key);

    if (savedValue != null && mounted) {
      setState(() {
        _visibility = EventVisibility.values.firstWhere(
          (e) => e.toString() == savedValue,
          orElse: () => EventVisibility.sharedWithName,
        );
      });
    }
  }

  /// Check if this is the first time user sees privacy picker
  Future<void> _checkFirstTimePrivacyPicker() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenPrivacyPicker = prefs.getBool('has_seen_privacy_picker') ?? false;

    if (!hasSeenPrivacyPicker && mounted) {
      setState(() => _showPrivacyTooltip = true);
      // Mark as seen
      await prefs.setBool('has_seen_privacy_picker', true);
    }
  }

  /// Dismiss the first-time privacy tooltip
  void _dismissPrivacyTooltip() {
    setState(() => _showPrivacyTooltip = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Apply a template to pre-fill fields
  void _applyTemplate(EventTemplate template) {
    final previousVisibility = _visibility;

    setState(() {
      _selectedTemplate = template;

      switch (template) {
        case EventTemplate.party:
          _titleController.text = 'Party';
          _category = EventCategory.friend;
          _emoji = '🎉';
          _startTime = const TimeOfDay(hour: 19, minute: 0);
          _endTime = const TimeOfDay(hour: 23, minute: 0);
          _visibility = EventVisibility.sharedWithName;
          _templateData = null; // No template data for simple party
          break;
        case EventTemplate.dinner:
          _titleController.text = 'Dinner';
          _category = EventCategory.friend;
          _emoji = '🍽️';
          _startTime = const TimeOfDay(hour: 19, minute: 0);
          _endTime = const TimeOfDay(hour: 21, minute: 0);
          _locationController.text = 'Restaurant';
          _visibility = EventVisibility.sharedWithName;
          _templateData = null; // No template data for simple dinner
          break;
        case EventTemplate.movieNight:
          _titleController.text = 'Movie Night';
          _category = EventCategory.friend;
          _emoji = '🎬';
          _startTime = const TimeOfDay(hour: 20, minute: 0);
          _endTime = const TimeOfDay(hour: 22, minute: 0);
          _visibility = EventVisibility.sharedWithName;
          _templateData = null; // No template data for movie night
          break;
        case EventTemplate.surpriseParty:
          _titleController.text = 'Surprise Birthday Party';
          _category = EventCategory.friend;
          _emoji = '🎁';
          _startTime = const TimeOfDay(hour: 19, minute: 0);
          _endTime = const TimeOfDay(hour: 22, minute: 0);
          _notesController.text = "Secret! Don't tell the birthday person";
          _visibility = EventVisibility.busyOnly; // CRITICAL: Hide from birthday person!
          _showMoreOptions = true;
          // Create SurprisePartyTemplateModel (user will configure later)
          _templateData = SurprisePartyTemplateModel();
          break;
        case EventTemplate.friendsgiving:
          _titleController.text = 'Friendsgiving';
          _category = EventCategory.holiday;
          _emoji = '🦃';
          _startTime = const TimeOfDay(hour: 18, minute: 0);
          _endTime = const TimeOfDay(hour: 21, minute: 0);
          _notesController.text = 'Potluck style - sign up for dishes';
          _visibility = EventVisibility.sharedWithName;
          _showMoreOptions = true;
          // Create PotluckTemplateModel (user will configure later)
          _templateData = PotluckTemplateModel();
          break;
      }
    });

    // Show warning if template changed privacy setting
    if (previousVisibility != _visibility) {
      final colorScheme = Theme.of(context).colorScheme;
      String warningMessage;

      if (template == EventTemplate.surpriseParty) {
        warningMessage = '🎁 Privacy set to "Shared as Busy" to keep the surprise secret!';
      } else {
        warningMessage = 'Template changed privacy to "${_getPrivacyLabel(_visibility)}"';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warningMessage,
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
          backgroundColor: colorScheme.primaryContainer,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      HapticFeedback.mediumImpact();
    }
  }

  /// Get human-readable label for privacy setting
  String _getPrivacyLabel(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return 'Private';
      case EventVisibility.busyOnly:
        return 'Shared as Busy';
      case EventVisibility.sharedWithName:
        return 'Shared with Details';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Check if form has unsaved changes
    final hasUnsavedChanges = _titleController.text.isNotEmpty ||
                              _locationController.text.isNotEmpty ||
                              _notesController.text.isNotEmpty;

    return PopScope<EventModel?>(
      canPop: !hasUnsavedChanges || widget.isEditMode,
      onPopInvokedWithResult: (bool didPop, EventModel? result) {
        if (didPop) return;
        _handleClose(context);
      },
      child: Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => _handleClose(context),
        ),
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Scrollable form content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 120 + bottomInset, // Space for bottom button + keyboard
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group context header (for proposal mode)
                  if (widget.isProposalMode && widget.groupName != null) ...[
                    _buildGroupContextHeader(colorScheme, appColors),
                    const SizedBox(height: 16),
                  ],

                  // Template chips (quick start) - personal events only
                  if (!widget.isEditMode && !widget.isProposalMode) ...[
                    _buildTemplateChips(colorScheme),
                    const SizedBox(height: 20),
                  ],

                  // Field 1: Title
                  _buildTitleField(colorScheme),
                  const SizedBox(height: 20),

                  // Field 2: Privacy (PROMOTED from field 8!)
                  _buildPrivacyCard(colorScheme, appColors),
                  const SizedBox(height: 20),

                  // Field 3: Date & Time (grouped card)
                  _buildDateTimeCard(colorScheme, appColors),
                  const SizedBox(height: 20),

                  // Field 4: Location (optional but visible)
                  _buildLocationField(colorScheme),
                  const SizedBox(height: 20),

                  // More Options (collapsed by default)
                  _buildMoreOptionsSection(colorScheme, appColors),
                ],
              ),
            ),
          ),

          // Sticky bottom CTA button
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: _buildBottomCTA(colorScheme),
          ),
        ],
      ),
    ), // Close Scaffold
    ); // Close PopScope
  }

  /// Handle privacy change with confirmation for Shared → Private transitions
  Future<void> _handlePrivacyChange(EventVisibility newVisibility) async {
    // If changing from Shared (sharedWithName or busyOnly) to Private
    final wasShared = _visibility == EventVisibility.sharedWithName ||
                      _visibility == EventVisibility.busyOnly;
    final goingPrivate = newVisibility == EventVisibility.private;

    if (wasShared && goingPrivate) {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: Icon(
              Icons.lock_outline,
              size: 48,
              color: colorScheme.primary,
            ),
            title: Text(
              'Make Event Private?',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            content: Text(
              'This event will be hidden from all groups. They won\'t see you\'re busy during this time.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            actions: [
              AdaptiveButton.text(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              AdaptiveButton.primary(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Make Private'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        setState(() => _visibility = newVisibility);
        HapticFeedback.mediumImpact();
      }
    } else {
      // No confirmation needed for other transitions
      setState(() => _visibility = newVisibility);
      HapticFeedback.selectionClick();
    }
  }

  /// Show privacy help sheet explaining Shadow Calendar system
  void _showPrivacyHelpSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'How Shadow Calendar works',
                          style: TextStyle(
                            fontSize: 13,
                            color: appColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Introduction
                    Text(
                      'Your Shadow Calendar automatically shares your availability with groups while respecting your privacy.',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Privacy options explanation
                    _buildHelpOption(
                      colorScheme: colorScheme,
                      appColors: appColors,
                      icon: Icons.people,
                      iconColor: const Color(0xFF10B981),
                      title: 'Shared with Details',
                      description: 'Groups see your event name and time. Best for coordinating with friends.',
                      example: 'They see: "Holiday Dinner at 7:00 PM"',
                    ),
                    const SizedBox(height: 16),

                    _buildHelpOption(
                      colorScheme: colorScheme,
                      appColors: appColors,
                      icon: Icons.remove_red_eye_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Shared as Busy',
                      description: 'Groups see you\'re busy but not why. Use for private appointments.',
                      example: 'They see: "Busy 2:00 PM - 3:00 PM"',
                    ),
                    const SizedBox(height: 16),

                    _buildHelpOption(
                      colorScheme: colorScheme,
                      appColors: appColors,
                      icon: Icons.lock,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Private',
                      description: 'Completely hidden from groups. They don\'t know you\'re busy.',
                      example: 'They see: Nothing (you appear free)',
                    ),
                    const SizedBox(height: 24),

                    // Tip box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pro Tip',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You can set different privacy defaults for each group in group settings.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: appColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  /// Build a help option explanation
  Widget _buildHelpOption({
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String example,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: appColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                example,
                style: TextStyle(
                  fontSize: 12,
                  color: appColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Handle close with unsaved changes confirmation
  void _handleClose(BuildContext context) {
    // Check if form has any data
    final hasData = _titleController.text.isNotEmpty ||
                    _locationController.text.isNotEmpty ||
                    _notesController.text.isNotEmpty;

    if (hasData && !widget.isEditMode) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
          actions: [
            AdaptiveButton.text(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            AdaptiveButton.text(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              isDestructive: true,
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Build template chips for quick event creation
  Widget _buildTemplateChips(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTemplateChip('🎉', 'Party', EventTemplate.party, colorScheme),
              const SizedBox(width: 8),
              _buildTemplateChip('🍽️', 'Dinner', EventTemplate.dinner, colorScheme),
              const SizedBox(width: 8),
              _buildTemplateChip('🎬', 'Movie', EventTemplate.movieNight, colorScheme),
              const SizedBox(width: 8),
              _buildTemplateChip('🎁', 'Surprise', EventTemplate.surpriseParty, colorScheme),
              const SizedBox(width: 8),
              _buildTemplateChip('🦃', 'Friendsgiving', EventTemplate.friendsgiving, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateChip(String emoji, String label, EventTemplate template, ColorScheme colorScheme) {
    final isSelected = _selectedTemplate == template;

    return Semantics(
      label: '$label template',
      hint: isSelected ? 'Currently selected' : 'Double tap to pre-fill event with $label defaults',
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _applyTemplate(template),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.15)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build title field
  Widget _buildTitleField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(color: colorScheme.error),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AdaptiveTextFormField(
          controller: _titleController,
          placeholder: 'Event name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            return null;
          },
          onChanged: (_) => setState(() {}), // Trigger rebuild to update CTA state
        ),
      ],
    );
  }

  /// Build privacy card (PROMOTED to field 2!)
  Widget _buildPrivacyCard(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Privacy',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
            Text('*', style: TextStyle(color: colorScheme.error)),
            const SizedBox(width: 4),
            // Info icon to open help sheet
            GestureDetector(
              onTap: () => _showPrivacyHelpSheet(context),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Who can see this event in groups?',
          style: TextStyle(
            fontSize: 12,
            color: appColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),

        // First-time user tooltip
        if (_showPrivacyTooltip) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Shadow Calendar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control what groups see about your events. Tap the ℹ️ icon above to learn more.',
                        style: TextStyle(
                          fontSize: 13,
                          color: appColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismissPrivacyTooltip,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Shared with Details (Recommended)
        _buildPrivacyOption(
          colorScheme: colorScheme,
          appColors: appColors,
          value: EventVisibility.sharedWithName,
          icon: Icons.people_outline,
          title: 'Shared with Details',
          description: 'Groups see event name',
          example: '"${_titleController.text.isEmpty ? "Holiday Dinner" : _titleController.text} at ${_startTime.format(context)}"',
          isRecommended: true,
        ),
        const SizedBox(height: 10),

        // Shared as Busy
        _buildPrivacyOption(
          colorScheme: colorScheme,
          appColors: appColors,
          value: EventVisibility.busyOnly,
          icon: Icons.visibility_outlined,
          title: 'Shared as Busy',
          description: 'Groups see "busy" only',
          example: '"Busy ${_startTime.format(context)} - ${_endTime.format(context)}"',
        ),
        const SizedBox(height: 10),

        // Private
        _buildPrivacyOption(
          colorScheme: colorScheme,
          appColors: appColors,
          value: EventVisibility.private,
          icon: Icons.lock,
          title: 'Private',
          description: 'Only you can see',
          example: 'Hidden from all groups',
        ),
      ],
    );
  }

  Widget _buildPrivacyOption({
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
    required EventVisibility value,
    required IconData icon,
    required String title,
    required String description,
    required String example,
    bool isRecommended = false,
  }) {
    final isSelected = _visibility == value;
    final recommendedHint = isRecommended ? ' Recommended.' : '';
    final selectedHint = isSelected ? 'Currently selected.' : 'Double tap to select.';

    return Semantics(
      label: '$title: $description. Example: $example.$recommendedHint',
      hint: selectedHint,
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _handlePrivacyChange(value),
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Icon
            Icon(
              icon,
              size: 22,
              color: isSelected ? colorScheme.primary : appColors.textMuted,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      example,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: appColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Build grouped date/time card
  Widget _buildDateTimeCard(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Date & Time',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
            Text('*', style: TextStyle(color: colorScheme.error)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date display
              Semantics(
                label: 'Date: ${TimezoneUtils.formatLocal(_startDate, 'EEEE, MMMM d, yyyy')}',
                hint: 'Double tap to change date',
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => _selectStartDate(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          TimezoneUtils.formatLocal(_startDate, 'EEEE, MMMM d, yyyy'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.edit,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Time display (if not all day)
              if (!_isAllDay) ...[
                Semantics(
                  label: 'Time: ${_startTime.format(context)} to ${_endTime.format(context)}',
                  hint: 'Double tap to change time',
                  button: true,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => _showTimePickerSheet(context),
                    child: Row(
                      children: [
                        Text(
                          '${_startTime.format(context)} - ${_endTime.format(context)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: appColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'All day',
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.textSecondary,
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
              const SizedBox(height: 12),

              // All Day toggle
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isAllDay = !_isAllDay),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isAllDay
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isAllDay
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isAllDay ? Icons.check_circle : Icons.circle_outlined,
                            size: 16,
                            color: _isAllDay ? colorScheme.primary : appColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'All Day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isAllDay ? FontWeight.w600 : FontWeight.w500,
                              color: _isAllDay ? colorScheme.primary : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  AdaptiveButton.text(
                    onPressed: () => _showDateTimePickerSheet(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build location field
  Widget _buildLocationField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(optional)',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AdaptiveTextFormField(
          controller: _locationController,
          placeholder: 'Add location',
          prefix: Icon(
            Icons.place_outlined,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  /// Build "More Options" expandable section
  Widget _buildMoreOptionsSection(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showMoreOptions = !_showMoreOptions),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  _showMoreOptions ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'More Options',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_showMoreOptions) ...[
          const SizedBox(height: 12),

          // Category picker
          _buildCategoryPicker(colorScheme),
          const SizedBox(height: 20),

          // Notes field
          _buildNotesField(colorScheme),
        ],
      ],
    );
  }

  /// Build category picker
  Widget _buildCategoryPicker(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: EventCategory.values.map((category) {
            final isSelected = _category == category;
            final categoryLabel = _getCategoryLabel(category);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: category != EventCategory.other ? 8 : 0,
                ),
                child: Semantics(
                  label: 'Category: $categoryLabel',
                  hint: isSelected ? 'Currently selected' : 'Double tap to select $categoryLabel category',
                  button: true,
                  selected: isSelected,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _category = category;
                        _emoji = _getDefaultEmoji(category);
                      });
                    },
                    child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getCategoryColor(category).withValues(alpha: 0.2)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _getCategoryColor(category)
                            : colorScheme.onSurface.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getDefaultEmoji(category),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoryLabel(category),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? _getCategoryColor(category)
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build notes field
  Widget _buildNotesField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes_outlined, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AdaptiveTextFormField(
          controller: _notesController,
          placeholder: 'Add notes (optional)',
          maxLines: 4,
        ),
      ],
    );
  }

  /// Build sticky bottom CTA button
  Widget _buildBottomCTA(ColorScheme colorScheme) {
    final isFormValid = _titleController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: AdaptiveButton.primary(
          onPressed: isFormValid ? _handleCTAPress : null,
          minWidth: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _getCTAButtonText(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Show time picker bottom sheet (platform-adaptive)
  void _showTimePickerSheet(BuildContext ctx) async {
    final startTime = await showAdaptiveTimePicker(
      context: ctx,
      initialTime: _startTime,
      helpText: 'Start Time',
    );

    if (startTime != null && mounted) {
      final endTime = await showAdaptiveTimePicker(
        context: context,
        initialTime: _endTime,
        helpText: 'End Time',
      );

      if (endTime != null && mounted) {
        setState(() {
          _startTime = startTime;
          _endTime = endTime;
        });
      }
    }
  }

  /// Show full date/time picker bottom sheet (platform-adaptive)
  void _showDateTimePickerSheet(BuildContext ctx) async {
    // First pick start date
    final startDate = await showAdaptiveDatePicker(
      context: ctx,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      helpText: 'Select Date',
    );

    if (startDate != null && mounted) {
      setState(() {
        _startDate = startDate;
        _endDate = startDate; // Same day by default
      });

      if (!_isAllDay && mounted) {
        _showTimePickerSheet(context);
      }
    }
  }

  /// Select start date (platform-adaptive)
  Future<void> _selectStartDate(BuildContext context) async {
    final now = TimezoneUtils.nowUtc().toLocal();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today,
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _startDate && mounted) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  /// Handle CTA button press
  /// In personal mode: saves the event
  /// In proposal mode: navigates to the GroupProposalWizard
  void _handleCTAPress() {
    if (widget.isProposalMode && widget.mode == EventCreationMode.groupProposal) {
      // Validate form first
      if (!_formKey.currentState!.validate()) {
        return;
      }

      // Navigate to the Group Proposal Wizard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GroupProposalWizard(
            groupId: widget.groupId!,
            groupName: widget.groupName!,
            groupMemberCount: widget.groupMemberCount!,
            initialDate: _startDate,
          ),
        ),
      );
    } else {
      // Personal event or edit mode - save the event
      _saveEvent();
    }
  }

  /// Save event
  void _saveEvent() {
    Logger.info('EventCreationScreen', '=== _saveEvent() called ===');
    Logger.info('EventCreationScreen', 'Title: ${_titleController.text}');
    Logger.info('EventCreationScreen', 'Start date: $_startDate');
    Logger.info('EventCreationScreen', 'Start time: $_startTime');
    Logger.info('EventCreationScreen', 'End time: $_endTime');
    Logger.info('EventCreationScreen', 'Is all-day: $_isAllDay');

    if (!_formKey.currentState!.validate()) {
      Logger.warning('EventCreationScreen', 'Form validation failed');
      return;
    }

    // Combine date and time (in local timezone)
    final startDateTime = _isAllDay
        ? DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0)
        : DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime.hour,
            _startTime.minute,
          );

    final endDateTime = _isAllDay
        ? DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59)
        : DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            _endTime.hour,
            _endTime.minute,
          );

    // Validate for DST transitions on timed events
    if (!_isAllDay && TimezoneUtils.isDSTTransition(startDateTime)) {
      final safeTime = TimezoneUtils.validateDSTSafe(startDateTime);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Start time ${TimezoneUtils.formatLocal(startDateTime, 'h:mm a')} falls during daylight saving transition. '
            'It will be adjusted to ${TimezoneUtils.formatLocal(safeTime, 'h:mm a')}.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // Validate event is not in the past
    final now = TimezoneUtils.nowUtc().toLocal();
    final today = DateTime(now.year, now.month, now.day);

    if (_isAllDay) {
      if (_startDate.isBefore(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot create events in the past'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    } else {
      if (startDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot create events in the past'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    // Validate end time is after start time
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('End time must be after start time'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Get authenticated user ID
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be logged in to create events'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Create or update event model
    final EventModel event;

    if (widget.isEditMode) {
      event = widget.eventToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        visibility: _visibility,
        category: _category,
        emoji: _emoji,
        templateData: _templateData,
        updatedAt: TimezoneUtils.nowUtc(),
      );
    } else {
      const uuid = Uuid();
      event = EventModel(
        id: uuid.v4(),
        userId: userId,
        title: _titleController.text.trim(),
        description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        visibility: _visibility,
        category: _category,
        emoji: _emoji,
        nativeCalendarId: null,
        templateData: _templateData,
        createdAt: DateTime.now(),
      );
    }

    // Haptic feedback for successful event creation
    HapticFeedback.mediumImpact();

    Logger.info('EventCreationScreen', 'Event created successfully, popping with event:');
    Logger.info('EventCreationScreen', '  - ID: ${event.id}');
    Logger.info('EventCreationScreen', '  - Title: ${event.title}');
    Logger.info('EventCreationScreen', '  - Start: ${event.startTime}');
    Logger.info('EventCreationScreen', '  - End: ${event.endTime}');

    Navigator.of(context).pop(event);
  }

  /// Get app bar title based on mode
  String _getAppBarTitle() {
    switch (widget.mode) {
      case EventCreationMode.personalEvent:
        return 'New Event';
      case EventCreationMode.groupProposal:
        return 'Propose Event';
      case EventCreationMode.editPersonalEvent:
        return 'Edit Event';
      case EventCreationMode.editGroupProposal:
        return 'Edit Proposal';
    }
  }

  /// Get CTA button text based on mode
  String _getCTAButtonText() {
    switch (widget.mode) {
      case EventCreationMode.personalEvent:
        return 'Create Event';
      case EventCreationMode.groupProposal:
        return 'Continue to Time Options';
      case EventCreationMode.editPersonalEvent:
        return 'Save Changes';
      case EventCreationMode.editGroupProposal:
        return 'Save Changes';
    }
  }

  /// Build group context header (shown in proposal mode)
  Widget _buildGroupContextHeader(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.12),
            colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          // Group icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people,
              color: colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Group name and member count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName ?? 'Group',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.groupMemberCount ?? 0} members will be notified',
                  style: TextStyle(
                    fontSize: 13,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Change group button (if not editing)
          if (!widget.isEditMode) ...[
            IconButton(
              icon: Icon(
                Icons.swap_horiz,
                size: 22,
                color: colorScheme.primary,
              ),
              onPressed: () {
                // TODO: Navigate back to group selection
                Navigator.of(context).pop();
              },
              tooltip: 'Change group',
            ),
          ],
        ],
      ),
    );
  }

  /// Get default emoji for a category
  String _getDefaultEmoji(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return '💻';
      case EventCategory.holiday:
        return '🦃';
      case EventCategory.friend:
        return '🎮';
      case EventCategory.other:
        return '🎯';
    }
  }

  /// Get category label
  String _getCategoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return 'Work';
      case EventCategory.holiday:
        return 'Holiday';
      case EventCategory.friend:
        return 'Friend';
      case EventCategory.other:
        return 'Other';
    }
  }

  /// Get category color for UI
  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return const Color(0xFF14B8A6);
      case EventCategory.holiday:
        return const Color(0xFFF97316);
      case EventCategory.friend:
        return const Color(0xFF8B5CF6);
      case EventCategory.other:
        return const Color(0xFFEC4899);
    }
  }
}
