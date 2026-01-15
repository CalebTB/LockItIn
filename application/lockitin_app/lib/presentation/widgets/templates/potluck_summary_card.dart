import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/event_template_model.dart';

/// Summary card for Potluck template
///
/// Features:
/// - Progress bar showing claimed vs total dishes
/// - Category breakdown with counts
/// - List of user's claimed dishes
/// - "View Full List" button to scroll to dish list
/// - Real-time updates when dishes change
///
/// **Pattern**: Compact summary card with key metrics and realtime subscription
class PotluckSummaryCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback? onViewFullList;

  const PotluckSummaryCard({
    super.key,
    required this.event,
    this.onViewFullList,
  });

  @override
  State<PotluckSummaryCard> createState() => _PotluckSummaryCardState();
}

class _PotluckSummaryCardState extends State<PotluckSummaryCard> {
  RealtimeChannel? _channel;
  late EventModel _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final supabase = Supabase.instance.client;

    _channel = supabase.channel('potluck-summary-${widget.event.id}');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.event.id,
          ),
          callback: (payload) {
            if (!mounted) return;

            try {
              final updatedEvent = EventModel.fromJson(payload.newRecord);
              setState(() {
                _currentEvent = updatedEvent;
              });

              Logger.info('PotluckSummaryCard', 'Real-time update received for event ${widget.event.id}');
            } catch (e) {
              Logger.error('PotluckSummaryCard', 'Failed to parse real-time update: $e');
            }
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            Logger.info('PotluckSummaryCard', 'Subscribed to real-time updates for event ${widget.event.id}');
          } else if (error != null) {
            Logger.error('PotluckSummaryCard', 'Real-time subscription error: $error');
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final template = _currentEvent.potluckTemplate;

    if (template == null) {
      return const SizedBox.shrink();
    }

    final dishes = template.dishes;
    final claimedCount = dishes.where((d) => d.isClaimed).length;
    final totalCount = dishes.length;
    final progress = totalCount > 0 ? claimedCount / totalCount : 0.0;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final userDishes = currentUserId != null
        ? template.getUserDishes(currentUserId)
        : <PotluckDish>[];

    // Category breakdown
    final categoryCounts = template.getCategoryCounts();

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '🍽️ Potluck Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Claimed Dishes',
                    style: TextStyle(
                      fontSize: 14,
                      color: appColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$claimedCount / $totalCount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: appColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          if (categoryCounts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),

            // Category breakdown
            Text(
              'BY CATEGORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: categoryCounts.entries.map((entry) {
                final category = entry.key;
                final count = entry.value;
                final icon = _getCategoryIcon(category);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: appColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        icon,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _capitalize(category),
                        style: TextStyle(
                          fontSize: 13,
                          color: appColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          if (userDishes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),

            // User's dishes
            Text(
              'YOUR DISHES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: appColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            ...userDishes.map((dish) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Text(
                      _getCategoryIcon(dish.category),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        dish.dishName,
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
          ],

          if (totalCount > 0) ...[
            const SizedBox(height: AppSpacing.lg),

            // View Full List button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewFullList,
                icon: const Icon(Icons.list, size: 18),
                label: const Text('View Full List'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
