import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/event_creation_screen.dart';
import '../providers/calendar_provider.dart';
import '../../core/services/event_service.dart';
import '../../data/models/event_model.dart';

/// Bottom sheet for proposing/creating a new event
/// Features quick templates and group selection
/// Styled with Sunset Coral Dark theme
class NewEventBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final DateTime? initialDate;

  const NewEventBottomSheet({
    super.key,
    required this.onClose,
    this.initialDate,
  });

  @override
  State<NewEventBottomSheet> createState() => _NewEventBottomSheetState();
}

class _NewEventBottomSheetState extends State<NewEventBottomSheet> {
  // Sunset Coral Dark Theme Colors
  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose100 = Color(0xFFFFE4E6);
  static const Color _orange500 = Color(0xFFF97316);
  static const Color _orange200 = Color(0xFFFED7AA);
  static const Color _amber500 = Color(0xFFF59E0B);
  static const Color _violet500 = Color(0xFF8B5CF6);
  static const Color _pink500 = Color(0xFFEC4899);
  static const Color _slate950 = Color(0xFF020617);

  final TextEditingController _eventNameController = TextEditingController();
  String? _selectedGroupId;

  // Placeholder groups - will be replaced with real data from GroupProvider
  final _groups = [
    _GroupOption(id: '1', name: 'Friendsgiving Crew', emoji: '🦃'),
    _GroupOption(id: '2', name: 'Game Night', emoji: '🎮'),
    _GroupOption(id: '3', name: 'Book Club', emoji: '📚'),
    _GroupOption(id: '4', name: 'Hiking Squad', emoji: '🥾'),
  ];

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_rose950, _rose950, _slate950],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Color(0x33F43F5E), width: 1), // rose-500/20
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _rose500.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_rose200, _orange200],
                      ).createShader(bounds),
                      child: const Text(
                        'Propose Event',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, color: _rose300),
                    ),
                  ],
                ),
              ),

              // Event name field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _rose200.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _eventNameController,
                      style: const TextStyle(color: _rose100, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "What's the occasion?",
                        hintStyle: TextStyle(color: _rose300.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: _rose900.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _rose500.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _rose500.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _rose400.withValues(alpha: 0.5), width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Group selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Group',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _rose200.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          final isSelected = _selectedGroupId == group.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() => _selectedGroupId = group.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              _rose500.withValues(alpha: 0.3),
                                              _orange500.withValues(alpha: 0.3),
                                            ],
                                          )
                                        : null,
                                    color: isSelected ? null : _rose900.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? _rose400.withValues(alpha: 0.5)
                                          : _rose500.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(group.emoji, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Text(
                                        group.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected ? _rose100 : _rose100,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quick templates
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Templates',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _rose200.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.5,
                      children: [
                        _buildTemplateButton(
                          '🎉',
                          'Party',
                          [_amber500.withValues(alpha: 0.2), _orange500.withValues(alpha: 0.2)],
                          _amber500.withValues(alpha: 0.3),
                        ),
                        _buildTemplateButton(
                          '🍽️',
                          'Dinner',
                          [_rose500.withValues(alpha: 0.2), _pink500.withValues(alpha: 0.2)],
                          _rose500.withValues(alpha: 0.3),
                        ),
                        _buildTemplateButton(
                          '🎬',
                          'Movie Night',
                          [_violet500.withValues(alpha: 0.2), _pink500.withValues(alpha: 0.2)],
                          _violet500.withValues(alpha: 0.3),
                        ),
                        _buildTemplateButton(
                          '🎁',
                          'Surprise',
                          [_pink500.withValues(alpha: 0.2), _rose500.withValues(alpha: 0.2)],
                          _pink500.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleContinue(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_rose500, _orange500],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _rose500.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateButton(
    String emoji,
    String label,
    List<Color> gradientColors,
    Color borderColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _eventNameController.text = label;
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _rose100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue(BuildContext context) async {
    widget.onClose();

    // Navigate to EventCreationScreen and await the result
    // TODO: Support groupProposal mode when group is selected
    final result = await Navigator.of(context).push<EventModel>(
      MaterialPageRoute(
        builder: (context) => EventCreationScreen(
          mode: EventCreationMode.personalEvent,
          initialDate: widget.initialDate ?? DateTime.now(),
        ),
      ),
    );

    // If an event was created, save it
    if (result != null && context.mounted) {
      try {
        // Save to native calendar and Supabase
        final savedEvent = await EventService.instance.createEvent(result);

        // Add to CalendarProvider for immediate UI update
        if (context.mounted) {
          context.read<CalendarProvider>().addEvent(savedEvent);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event created successfully'),
              backgroundColor: Color(0xFF10B981), // Emerald-500
            ),
          );
        }
      } catch (e) {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create event: ${e.toString()}'),
              backgroundColor: const Color(0xFFF43F5E), // Rose-500
            ),
          );
        }
      }
    }
  }
}

class _GroupOption {
  final String id;
  final String name;
  final String emoji;

  const _GroupOption({
    required this.id,
    required this.name,
    required this.emoji,
  });
}
