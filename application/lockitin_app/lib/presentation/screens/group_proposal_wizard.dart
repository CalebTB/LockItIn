import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/proposal_service.dart';
import '../../core/services/event_service.dart';
import '../../core/services/smart_time_suggestion_service.dart';
import '../../data/models/event_model.dart';
import '../../data/models/proposal_time_option.dart';

/// Group Proposal Wizard - 3-step flow for creating event proposals
///
/// Step 1: Event Details (title, location, description)
/// Step 2: Time Options (add 2-5 time slots for voting)
/// Step 3: Review & Send (preview and submit proposal)
class GroupProposalWizard extends StatefulWidget {
  final String groupId;
  final String groupName;
  final int groupMemberCount;
  final DateTime? initialDate;
  /// Optional start time for pre-filling the first time option
  /// (e.g., when user taps a free time slot on the timeline)
  final DateTime? initialStartTime;
  /// Optional end time for pre-filling the first time option
  final DateTime? initialEndTime;
  /// Optional member events for smart time suggestions
  /// If not provided, the wizard will fetch them
  final Map<String, List<EventModel>>? memberEvents;
  /// Member user IDs for fetching shadow calendar events
  /// Required if memberEvents is not provided
  final List<String>? memberIds;

  const GroupProposalWizard({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupMemberCount,
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
    this.memberEvents,
    this.memberIds,
  });

  @override
  State<GroupProposalWizard> createState() => _GroupProposalWizardState();
}

class _GroupProposalWizardState extends State<GroupProposalWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Time options state
  List<ProposalTimeOption> _timeOptions = [];
  DateTime _votingDeadline = DateTime.now().add(const Duration(hours: 48));

  // Loading state
  bool _isSubmitting = false;

  // Smart time suggestion state
  final SmartTimeSuggestionService _suggestionService = SmartTimeSuggestionService();
  Map<String, List<EventModel>> _memberEvents = {};

  @override
  void initState() {
    super.initState();
    // Start with one time option
    // If initialStartTime/EndTime provided (from tapping a free slot), use those
    // Otherwise default to 7pm-9pm on the initial date
    final DateTime startTime;
    final DateTime endTime;

    if (widget.initialStartTime != null && widget.initialEndTime != null) {
      // Use the time slot the user tapped
      startTime = widget.initialStartTime!;
      endTime = widget.initialEndTime!;
    } else {
      // Default to 7pm-9pm on the initial date
      final initialDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
      startTime = DateTime(initialDate.year, initialDate.month, initialDate.day, 19, 0);
      endTime = DateTime(initialDate.year, initialDate.month, initialDate.day, 21, 0);
    }

    _timeOptions = [
      ProposalTimeOption(
        startTime: startTime,
        endTime: endTime,
      ),
    ];

    // Initialize member events for smart suggestions
    _initializeMemberEvents();
  }

  /// Load member events for smart time suggestions
  Future<void> _initializeMemberEvents() async {
    // If member events were passed, use them
    if (widget.memberEvents != null && widget.memberEvents!.isNotEmpty) {
      setState(() {
        _memberEvents = widget.memberEvents!;
      });
      return;
    }

    // If member IDs were passed, fetch their events
    if (widget.memberIds != null && widget.memberIds!.isNotEmpty) {
      await _fetchMemberEvents(widget.memberIds!);
    }
    // If neither was passed, we'll use fallback suggestions
  }

  /// Fetch shadow calendar events for the given member IDs
  Future<void> _fetchMemberEvents(List<String> memberIds) async {
    try {
      // Fetch shadow calendar for the next 14 days
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(const Duration(days: 14));

      final shadowEntries = await EventService.instance.fetchGroupShadowCalendar(
        memberUserIds: memberIds,
        startDate: startDate,
        endDate: endDate,
      );

      final events = EventService.instance.shadowToEventModels(shadowEntries);

      if (mounted) {
        setState(() {
          _memberEvents = events;
        });
      }
    } catch (e) {
      // Silently fail - we'll use fallback suggestions
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep > 0 ? Icons.arrow_back : Icons.close,
            color: colorScheme.onSurface,
          ),
          onPressed: _handleBack,
        ),
        title: Text(
          'Propose Event',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildStepIndicator(colorScheme, appColors),
        ),
      ),
      body: Column(
        children: [
          // PageView for steps
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildStep1EventDetails(colorScheme, appColors),
                _buildStep2TimeOptions(colorScheme, appColors),
                _buildStep3Review(colorScheme, appColors),
              ],
            ),
          ),

          // Bottom navigation buttons
          _buildBottomNavigation(colorScheme),
        ],
      ),
    );
  }

  /// Build step indicator (dots with connecting lines)
  Widget _buildStepIndicator(ColorScheme colorScheme, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          final stepLabels = ['Details', 'Times', 'Review'];

          return Row(
            children: [
              Column(
                children: [
                  // Step circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted || isCurrent
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      border: isCurrent
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(Icons.check, size: 18, color: colorScheme.onPrimary)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCurrent
                                    ? colorScheme.onPrimary
                                    : appColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stepLabels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color: isCurrent ? colorScheme.primary : appColors.textMuted,
                    ),
                  ),
                ],
              ),
              // Connector line (except after last step)
              if (index < 2) ...[
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: isCompleted
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  /// Step 1: Event Details
  Widget _buildStep1EventDetails(ColorScheme colorScheme, AppColorsExtension appColors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group context header
            _buildGroupContextHeader(colorScheme, appColors),
            const SizedBox(height: 20),

            // Title field
            _buildLabeledField(
              colorScheme,
              appColors,
              label: 'Event Title',
              required: true,
              child: TextFormField(
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                decoration: _inputDecoration(colorScheme, 'What are you planning?'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 20),

            // Location field
            _buildLabeledField(
              colorScheme,
              appColors,
              label: 'Location',
              required: false,
              child: TextFormField(
                controller: _locationController,
                decoration: _inputDecoration(colorScheme, 'Add a location (optional)'),
              ),
            ),
            const SizedBox(height: 20),

            // Description field
            _buildLabeledField(
              colorScheme,
              appColors,
              label: 'Description',
              required: false,
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(colorScheme, 'Add details for your group (optional)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 2: Time Options
  Widget _buildStep2TimeOptions(ColorScheme colorScheme, AppColorsExtension appColors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Suggest Time Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add 2-5 time options for your group to vote on',
            style: TextStyle(
              fontSize: 13,
              color: appColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Time option cards
          ..._timeOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTimeOptionCard(index, option, colorScheme, appColors),
            );
          }),

          // Add option button (max 5 options)
          if (_timeOptions.length < 5) ...[
            OutlinedButton.icon(
              onPressed: _addTimeOption,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Another Option'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: colorScheme.primary),
              ),
            ),
          ],

          // Warning if < 2 options
          if (_timeOptions.length < 2) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add at least 2 time options for voting',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Voting deadline
          _buildLabeledField(
            colorScheme,
            appColors,
            label: 'Voting Deadline',
            required: true,
            child: GestureDetector(
              onTap: () => _selectVotingDeadline(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, MMM d, yyyy • h:mm a').format(_votingDeadline),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.edit, size: 18, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 3: Review & Send
  Widget _buildStep3Review(ColorScheme colorScheme, AppColorsExtension appColors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Review Your Proposal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.groupMemberCount} members will be notified',
            style: TextStyle(
              fontSize: 13,
              color: appColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Event summary card
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
                // Group badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            widget.groupName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  _titleController.text.isEmpty ? 'Untitled Event' : _titleController.text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),

                // Location (if provided)
                if (_locationController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: appColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        _locationController.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],

                // Description (if provided)
                if (_descriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Time options preview
          Text(
            'Time Options',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_timeOptions.length, (index) {
            final option = _timeOptions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${DateFormat('EEE, MMM d').format(option.startTime)} • ${DateFormat('h:mm a').format(option.startTime)} - ${DateFormat('h:mm a').format(option.endTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Voting deadline
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: appColors.textMuted),
              const SizedBox(width: 8),
              Text(
                'Voting ends: ${DateFormat('EEE, MMM d • h:mm a').format(_votingDeadline)}',
                style: TextStyle(
                  fontSize: 13,
                  color: appColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Edit buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goToStep(0),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Details'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goToStep(1),
                  icon: const Icon(Icons.access_time, size: 18),
                  label: const Text('Edit Times'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build time option card
  Widget _buildTimeOptionCard(
    int index,
    ProposalTimeOption option,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final dateLabel = DateFormat('EEEE, MMMM d').format(option.startTime);
    final timeLabel = '${DateFormat('h:mm a').format(option.startTime)} to ${DateFormat('h:mm a').format(option.endTime)}';
    final deleteHint = _timeOptions.length > 1 ? 'Use delete button or swipe left to remove.' : '';
    final semanticLabel = 'Option ${index + 1}: $dateLabel, $timeLabel. $deleteHint';

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Dismissible(
        key: Key('time_option_$index'),
        direction: _timeOptions.length > 1
            ? DismissDirection.endToStart
            : DismissDirection.none,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => _removeTimeOption(index),
        child: GestureDetector(
          onTap: () => _editTimeOption(index, option),
          child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Option number badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Date and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(option.startTime),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('h:mm a').format(option.startTime)} - ${DateFormat('h:mm a').format(option.endTime)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    onPressed: () => _editTimeOption(index, option),
                    tooltip: 'Edit time option',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  // Delete button (only show if more than 1 option)
                  if (_timeOptions.length > 1) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: colorScheme.error,
                      ),
                      onPressed: () => _confirmDeleteTimeOption(index),
                      tooltip: 'Delete time option',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Build group context header
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.groupMemberCount} members will vote',
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
    );
  }

  /// Build labeled field wrapper
  Widget _buildLabeledField(
    ColorScheme colorScheme,
    AppColorsExtension appColors, {
    required String label,
    required bool required,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: colorScheme.error)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  /// Build input decoration
  InputDecoration _inputDecoration(ColorScheme colorScheme, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Build bottom navigation buttons
  Widget _buildBottomNavigation(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
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
        child: Row(
          children: [
            // Back button (except on first step)
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, Platform.isIOS ? 50 : 56),
                    side: BorderSide(color: colorScheme.primary),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Next / Send button
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _canProceed() ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                  disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
                  minimumSize: Size(double.infinity, Platform.isIOS ? 50 : 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                        ),
                      )
                    : Text(
                        _getNextButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get the text for the next/submit button
  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Continue to Times';
      case 1:
        return 'Review Proposal';
      case 2:
        return 'Send to Group';
      default:
        return 'Next';
    }
  }

  /// Check if user can proceed to the next step
  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _titleController.text.trim().isNotEmpty;
      case 1:
        return _timeOptions.length >= 2;
      case 2:
        return !_isSubmitting;
      default:
        return true;
    }
  }

  /// Handle back button press
  void _handleBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Show confirmation dialog
      _showExitConfirmation();
    }
  }

  /// Handle next/submit button press
  void _handleNext() {
    if (_currentStep < 2) {
      // Validate current step
      if (_currentStep == 0 && !_formKey.currentState!.validate()) {
        return;
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit proposal
      _submitProposal();
    }
  }

  /// Go to a specific step
  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Add a new time option using smart suggestions
  ///
  /// Uses the SmartTimeSuggestionService to find the next best available
  /// time slot based on group availability. Falls back to "next day same time"
  /// if no member events are available.
  void _addTimeOption() {
    // Calculate preferred duration based on existing options
    final preferredDuration = _timeOptions.isNotEmpty
        ? _timeOptions.last.endTime
            .difference(_timeOptions.last.startTime)
            .inMinutes
        : 120;

    // Use smart suggestion service to find the best next option
    final suggestion = _suggestionService.suggestNextBestOption(
      memberEvents: _memberEvents,
      existingOptions: _timeOptions,
      preferredDuration: preferredDuration,
      searchDays: 7,
    );

    if (suggestion != null) {
      setState(() {
        _timeOptions.add(suggestion);
      });
    } else {
      // Fallback: add next day at same time
      final lastOption = _timeOptions.isNotEmpty
          ? _timeOptions.last
          : ProposalTimeOption(
              startTime: DateTime.now(),
              endTime: DateTime.now().add(const Duration(hours: 2)),
            );

      setState(() {
        _timeOptions.add(ProposalTimeOption(
          startTime: lastOption.startTime.add(const Duration(days: 1)),
          endTime: lastOption.endTime.add(const Duration(days: 1)),
        ));
      });
    }
  }

  /// Remove a time option
  void _removeTimeOption(int index) {
    if (_timeOptions.length > 1) {
      setState(() {
        _timeOptions.removeAt(index);
      });
    }
  }

  /// Show confirmation dialog before deleting a time option
  void _confirmDeleteTimeOption(int index) {
    final option = _timeOptions[index];
    final dateLabel = DateFormat('EEE, MMM d').format(option.startTime);
    final timeLabel = '${DateFormat('h:mm a').format(option.startTime)} - ${DateFormat('h:mm a').format(option.endTime)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Option?'),
        content: Text('Remove "$dateLabel, $timeLabel" from the proposal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeTimeOption(index);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Edit a time option
  Future<void> _editTimeOption(int index, ProposalTimeOption option) async {
    // Show date picker first
    final date = await showDatePicker(
      context: context,
      initialDate: option.startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    // Show start time picker
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(option.startTime),
      helpText: 'Start Time',
    );

    if (startTime == null || !mounted) return;

    // Show end time picker
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(option.endTime),
      helpText: 'End Time',
    );

    if (endTime == null) return;

    setState(() {
      _timeOptions[index] = ProposalTimeOption(
        startTime: DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute),
        endTime: DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute),
      );
    });
  }

  /// Select voting deadline
  Future<void> _selectVotingDeadline(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _votingDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: this.context,
      initialTime: TimeOfDay.fromDateTime(_votingDeadline),
    );

    if (time == null || !mounted) return;

    setState(() {
      _votingDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  /// Show exit confirmation dialog
  void _showExitConfirmation() {
    final hasData = _titleController.text.isNotEmpty ||
        _locationController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _timeOptions.length > 1;

    if (hasData) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Proposal?'),
          content: const Text('You have unsaved changes. Are you sure you want to discard this proposal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'Discard',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Submit the proposal
  Future<void> _submitProposal() async {
    setState(() => _isSubmitting = true);

    try {
      // Create proposal via ProposalService
      await ProposalService.instance.createProposal(
        groupId: widget.groupId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        votingDeadline: _votingDeadline,
        timeOptions: _timeOptions,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proposal sent to ${widget.groupName}!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate back with success result
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send proposal: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
