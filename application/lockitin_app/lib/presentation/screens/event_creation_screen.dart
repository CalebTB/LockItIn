import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/event_model.dart';
import '../providers/auth_provider.dart';

/// Event creation/editing screen with form for all event fields
/// Includes title, date/time pickers, location, notes, and privacy settings
/// When eventToEdit is provided, the form is pre-filled for editing
class EventCreationScreen extends StatefulWidget {
  final DateTime? initialDate;
  final EventModel? eventToEdit;

  const EventCreationScreen({
    super.key,
    this.initialDate,
    this.eventToEdit,
  });

  /// Check if this screen is in edit mode
  bool get isEditMode => eventToEdit != null;

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
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
  bool _isAllDay = false;

  @override
  void initState() {
    super.initState();

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
      // Check if it's an all-day event (starts at midnight and ends at 23:59)
      _isAllDay = event.startTime.hour == 0 &&
                  event.startTime.minute == 0 &&
                  event.endTime.hour == 23 &&
                  event.endTime.minute == 59;
    } else {
      // Create mode: use defaults
      _startDate = widget.initialDate ?? DateTime.now();
      _endDate = _startDate; // Default to same day
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isEditMode ? 'Edit Event' : 'New Event',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Event name',
              required: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Date pickers (start and end)
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    colorScheme,
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _selectStartDate(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePicker(
                    colorScheme,
                    label: 'End Date',
                    date: _endDate,
                    onTap: () => _selectEndDate(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // All Day checkbox
            _buildAllDayCheckbox(colorScheme),

            if (!_isAllDay) ...[
              const SizedBox(height: 20),

              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      colorScheme,
                      label: 'Start Time',
                      time: _startTime,
                      onTap: () => _selectStartTime(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      colorScheme,
                      label: 'End Time',
                      time: _endTime,
                      onTap: () => _selectEndTime(context),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Location field
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'Add location (optional)',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 20),

            // Privacy settings
            _buildPrivacyPicker(colorScheme),

            const SizedBox(height: 20),

            // Notes field
            _buildTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Add notes (optional)',
              maxLines: 5,
              icon: Icons.notes_outlined,
            ),
          ],
        ),
      ),
    );
  }

  /// Build text field with consistent styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
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
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Build date picker field
  Widget _buildDatePicker(
    ColorScheme colorScheme, {
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build time picker field
  Widget _buildTimePicker(
    ColorScheme colorScheme, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build All Day checkbox
  Widget _buildAllDayCheckbox(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        value: _isAllDay,
        onChanged: (value) {
          setState(() {
            _isAllDay = value ?? false;
          });
        },
        title: Text(
          'All Day',
          style: TextStyle(
            fontSize: 15,
            fontWeight: _isAllDay ? FontWeight.w600 : FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          _isAllDay ? 'Event lasts all day' : 'Specify start and end times',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        activeColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  /// Build privacy settings picker
  Widget _buildPrivacyPicker(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        RadioGroup<EventVisibility>(
          groupValue: _visibility,
          onChanged: (value) {
            if (value != null) {
              setState(() => _visibility = value);
            }
          },
          child: Column(
            children: EventVisibility.values.map((visibility) {
              final isSelected = _visibility == visibility;
              return RadioListTile<EventVisibility>(
                value: visibility,
                title: Text(
                  _getVisibilityLabel(visibility),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _getVisibilityDescription(visibility),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                activeColor: colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Select start date
  Future<void> _selectStartDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today, // Cannot select past dates
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before new start date, update it
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  /// Select end date
  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate, // End date must be on or after start date
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _endDate) {
      setState(() => _endDate = picked);
    }
  }

  /// Select start time
  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // Only auto-adjust end time if same day and end time is before start time
        if (_startDate.year == _endDate.year &&
            _startDate.month == _endDate.month &&
            _startDate.day == _endDate.day) {
          if (_endTime.hour < _startTime.hour ||
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        }
      });
    }
  }

  /// Select end time
  Future<void> _selectEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked != null && picked != _endTime) {
      setState(() => _endTime = picked);
    }
  }

  /// Save event
  void _saveEvent() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Combine date and time
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

    // Validate event is not in the past (skip for all-day events on current day)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // For all-day events, only check if start date is before today
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
      // For timed events, check exact start time
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
      // User not authenticated - this shouldn't happen but handle gracefully
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
      // Edit mode: preserve original IDs and update fields
      event = widget.eventToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        visibility: _visibility,
        updatedAt: DateTime.now(),
      );
    } else {
      // Create mode: generate new IDs
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
        nativeCalendarId: null,
        createdAt: DateTime.now(),
      );
    }

    // Return the event to the caller (calendar/detail screen will handle save)
    Navigator.of(context).pop(event);
  }

  /// Get visibility label
  String _getVisibilityLabel(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return 'Private';
      case EventVisibility.sharedWithName:
        return 'Shared with Details';
      case EventVisibility.busyOnly:
        return 'Shared as Busy';
    }
  }

  /// Get visibility description
  String _getVisibilityDescription(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return 'Only you can see this event';
      case EventVisibility.sharedWithName:
        return 'Friends can see event name and time';
      case EventVisibility.busyOnly:
        return 'Friends see you\'re busy without details';
    }
  }
}
