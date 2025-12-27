import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';

/// Event creation screen with form for all event fields
/// Includes title, date/time pickers, location, notes, and privacy settings
class EventCreationScreen extends StatefulWidget {
  final DateTime? initialDate;

  const EventCreationScreen({
    super.key,
    this.initialDate,
  });

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  EventVisibility _visibility = EventVisibility.sharedWithName;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);
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
          'New Event',
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

            // Date picker
            _buildDatePicker(colorScheme),

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
  Widget _buildDatePicker(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
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
                  Icons.calendar_today,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
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
        Column(
          children: EventVisibility.values.map((visibility) {
            final isSelected = _visibility == visibility;
            return RadioListTile<EventVisibility>(
              value: visibility,
              groupValue: _visibility,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _visibility = value);
                }
              },
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
      ],
    );
  }

  /// Select date
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
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
        // Auto-adjust end time if it's before start time
        if (_endTime.hour < _startTime.hour ||
            (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
          _endTime = TimeOfDay(
            hour: (_startTime.hour + 1) % 24,
            minute: _startTime.minute,
          );
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
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    // Validate end time is after start time
    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create event model
    final event = EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current-user',
      title: _titleController.text.trim(),
      description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      visibility: _visibility,
      nativeCalendarId: null,
      createdAt: DateTime.now(),
    );

    // TODO: Save event to database/provider
    // For now, just pop with the event
    Navigator.of(context).pop(event);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event created successfully'),
        backgroundColor: Colors.green,
      ),
    );
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
