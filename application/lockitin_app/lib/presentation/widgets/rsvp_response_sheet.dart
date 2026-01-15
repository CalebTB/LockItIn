import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/rsvp_provider.dart';

/// Modal bottom sheet for responding to event invitation
///
/// Features:
/// - Four RSVP options: Going, Maybe, Can't Go, No Response
/// - Visual selection with radio buttons
/// - Save button with loading state
/// - Error handling
class RsvpResponseSheet extends StatefulWidget {
  final String eventId;
  final String userId;
  final String? currentStatus; // Current RSVP status (or null if not responded)

  const RsvpResponseSheet({
    super.key,
    required this.eventId,
    required this.userId,
    this.currentStatus,
  });

  @override
  State<RsvpResponseSheet> createState() => _RsvpResponseSheetState();
}

class _RsvpResponseSheetState extends State<RsvpResponseSheet> {
  String? _selectedStatus;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
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
                        'RSVP to Event',
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

              Text(
                'WILL YOU ATTEND?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: appColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // RSVP Options
              _buildOption(
                colorScheme: colorScheme,
                appColors: appColors,
                value: 'accepted',
                label: 'Going',
                icon: Icons.check_circle,
                color: appColors.success,
              ),
              _buildOption(
                colorScheme: colorScheme,
                appColors: appColors,
                value: 'maybe',
                label: 'Maybe',
                icon: Icons.help_outline,
                color: appColors.warning,
              ),
              _buildOption(
                colorScheme: colorScheme,
                appColors: appColors,
                value: 'declined',
                label: "Can't Go",
                icon: Icons.cancel_outlined,
                color: Colors.red,
              ),
              _buildOption(
                colorScheme: colorScheme,
                appColors: appColors,
                value: 'pending',
                label: 'No Response',
                icon: Icons.radio_button_unchecked,
                color: appColors.textMuted,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _selectedStatus == widget.currentStatus
                      ? null
                      : _handleSubmit,
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
                          'Save RSVP',
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
    );
  }

  Widget _buildOption({
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedStatus == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = value;
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
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? colorScheme.primary : appColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedStatus == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final rsvpProvider = Provider.of<RSVPProvider>(context, listen: false);
      await rsvpProvider.updateRsvpStatus(
        widget.eventId,
        widget.userId,
        _selectedStatus!,
      );

      if (mounted) {
        Navigator.pop(context, _selectedStatus); // Return new status
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update RSVP: $e');
      }
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
