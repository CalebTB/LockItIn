import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/member_utils.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/event_template_model.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/group_provider.dart';

/// Widget for displaying and managing potluck dishes
///
/// Features:
/// - Lists dishes grouped by category (mains, sides, desserts, drinks, appetizers)
/// - Shows claimed vs unclaimed status
/// - Tap to claim/unclaim dishes
/// - Long press to show dish menu (view details, delete)
/// - Visual distinction between claimed/unclaimed
/// - Shows claimer's name and avatar
/// - All 4 UI states: loading, empty, error, success (Pattern 9)
///
/// **Pattern**: Follows SurprisePartyTaskList structure
class PotluckDishList extends StatefulWidget {
  final EventModel event;
  final VoidCallback? onAddDish;

  const PotluckDishList({
    super.key,
    required this.event,
    this.onAddDish,
  });

  @override
  State<PotluckDishList> createState() => _PotluckDishListState();
}

class _PotluckDishListState extends State<PotluckDishList> {
  // Optimistic updates: track dishes being claimed/unclaimed
  final Map<String, bool> _optimisticClaims = {};
  bool _isLoading = false;
  String? _error;

  // Realtime subscription
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

    Logger.info('PotluckDishList', '🔌 Setting up realtime subscription for event ${widget.event.id}');

    _channel = supabase.channel('potluck-event-${widget.event.id}');

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
            Logger.info('PotluckDishList', '📨 Real-time callback triggered! Payload keys: ${payload.newRecord.keys.toList()}');

            if (!mounted) {
              Logger.warning('PotluckDishList', '⚠️  Widget not mounted, skipping update');
              return;
            }

            try {
              final updatedEvent = EventModel.fromJson(payload.newRecord);
              Logger.info('PotluckDishList', '✅ Successfully parsed updated event. Dishes count: ${updatedEvent.potluckTemplate?.dishes.length ?? 0}');

              setState(() {
                _currentEvent = updatedEvent;
              });

              Logger.info('PotluckDishList', '🔄 UI state updated with new event data');
            } catch (e, stack) {
              Logger.error('PotluckDishList', '❌ Failed to parse real-time update: $e\n$stack');
            }
          },
        )
        .subscribe((status, error) {
          Logger.info('PotluckDishList', '📡 Subscription status changed: $status');

          if (status == RealtimeSubscribeStatus.subscribed) {
            Logger.info('PotluckDishList', '✅ Successfully subscribed to real-time updates for event ${widget.event.id}');
          } else if (status == RealtimeSubscribeStatus.closed) {
            Logger.warning('PotluckDishList', '⚠️  Subscription closed for event ${widget.event.id}');
          } else if (status == RealtimeSubscribeStatus.channelError) {
            Logger.error('PotluckDishList', '❌ Channel error for event ${widget.event.id}');
          } else if (status == RealtimeSubscribeStatus.timedOut) {
            Logger.error('PotluckDishList', '⏱️  Subscription timed out for event ${widget.event.id}');
          }

          if (error != null) {
            Logger.error('PotluckDishList', '❌ Real-time subscription error: $error');
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

    // State 1: Loading
    if (_isLoading) {
      return _buildLoadingState(appColors);
    }

    // State 2: Error
    if (_error != null) {
      return _buildErrorState(appColors, colorScheme);
    }

    final dishes = template.dishes;

    // State 3: Empty
    if (dishes.isEmpty) {
      return _buildEmptyState(appColors, colorScheme);
    }

    // State 4: Success - Group dishes by category
    final dishesByCategory = _groupDishesByCategory(dishes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Potluck Dishes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (widget.onAddDish != null)
              TextButton.icon(
                onPressed: widget.onAddDish,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Dishes grouped by category
        ...PotluckTemplateModel.standardCategories.map((category) {
          final categoryDishes = dishesByCategory[category] ?? [];
          if (categoryDishes.isEmpty) {
            return const SizedBox.shrink();
          }

          final claimedCount =
              categoryDishes.where((d) => d.isClaimed).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(
                context,
                category,
                claimedCount,
                categoryDishes.length,
                appColors,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...categoryDishes.map((dish) => _buildDishItem(
                    context,
                    dish,
                    template,
                  )),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        }),
      ],
    );
  }

  // State 1: Loading
  Widget _buildLoadingState(AppColorsExtension appColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            CircularProgressIndicator(color: appColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading dishes...',
              style: TextStyle(
                color: appColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // State 2: Error
  Widget _buildErrorState(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load dishes',
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(
                color: appColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = false;
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // State 3: Empty
  Widget _buildEmptyState(
      AppColorsExtension appColors, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.restaurant,
              size: 48,
              color: appColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No dishes yet',
              style: TextStyle(
                color: appColors.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap "Add" to contribute your first dish',
              style: TextStyle(
                color: appColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Add button for empty state
            if (widget.onAddDish != null)
              ElevatedButton.icon(
                onPressed: widget.onAddDish,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Dish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, List<PotluckDish>> _groupDishesByCategory(
      List<PotluckDish> dishes) {
    final grouped = <String, List<PotluckDish>>{};
    for (final category in PotluckTemplateModel.standardCategories) {
      grouped[category] = [];
    }
    for (final dish in dishes) {
      grouped[dish.category]?.add(dish);
    }
    return grouped;
  }

  Widget _buildCategoryHeader(
    BuildContext context,
    String category,
    int claimedCount,
    int totalCount,
    AppColorsExtension appColors,
  ) {
    final categoryIcon = _getCategoryIcon(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        '$categoryIcon ${category.toUpperCase()} ($claimedCount/$totalCount)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: appColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDishItem(
    BuildContext context,
    PotluckDish dish,
    PotluckTemplateModel template,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Check optimistic state
    final isOptimisticallyClaimed = _optimisticClaims[dish.id];
    final effectiveIsClaimed =
        isOptimisticallyClaimed ?? dish.isClaimed;
    final isClaimedByMe = dish.userId == currentUserId;

    return InkWell(
      onTap: () => _toggleClaim(context, dish),
      onLongPress: () => _showDishMenu(context, dish),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: appColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isClaimedByMe
                ? colorScheme.primary
                : appColors.cardBorder,
            width: isClaimedByMe ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Claim status icon
            Icon(
              effectiveIsClaimed
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: effectiveIsClaimed
                  ? appColors.success
                  : appColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),

            // Dish details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dish name
                  Text(
                    dish.dishName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  // Description (if present)
                  if (dish.description != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dish.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: appColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Serving size & dietary info
                  if (dish.servingSize != null ||
                      dish.dietaryInfo.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (dish.servingSize != null)
                          _buildInfoChip(
                            dish.servingSize!,
                            Icons.people,
                            appColors,
                          ),
                        ...dish.dietaryInfo.map((info) => _buildInfoChip(
                              _capitalize(info),
                              Icons.eco,
                              appColors,
                            )),
                      ],
                    ),
                  ],

                  // Claimer info
                  if (effectiveIsClaimed && dish.userId != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildClaimerInfo(context, dish.userId!, appColors),
                  ],
                ],
              ),
            ),

            // More menu icon
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: appColors.textSecondary,
                size: 20,
              ),
              onPressed: () => _showDishMenu(context, dish),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
      String label, IconData icon, AppColorsExtension appColors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: appColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: appColors.success),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: appColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimerInfo(
      BuildContext context, String userId, AppColorsExtension appColors) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        // Find the user in group members (nullable)
        final members = groupProvider.selectedGroupMembers;
        final user = members.isEmpty
            ? null
            : members.cast<dynamic>().firstWhere(
                  (m) => m.userId == userId,
                  orElse: () => null,
                );

        final userName = user?.fullName ?? 'Unknown';
        final memberColor = MemberUtils.getColorById(userId);

        return Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: memberColor.withValues(alpha: 0.2),
              child: Text(
                MemberUtils.getInitials(userName),
                style: TextStyle(
                  fontSize: 10,
                  color: memberColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Claimed by $userName',
              style: TextStyle(
                fontSize: 12,
                color: appColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleClaim(BuildContext context, PotluckDish dish) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final template = _currentEvent.potluckTemplate!;

    // Capture messenger and theme before async gap
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    // Check if user can claim (dish limit)
    if (!dish.isClaimed && !template.canUserAddDish(currentUserId)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'You\'ve reached your dish limit (${template.maxDishesPerPerson} dishes)',
          ),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // Optimistic update
    setState(() {
      _optimisticClaims[dish.id] = !dish.isClaimed;
    });

    try {
      await provider.togglePotluckDishClaim(_currentEvent.id, dish.id);

      // Clear optimistic state on success
      if (!mounted) return;
      setState(() {
        _optimisticClaims.remove(dish.id);
      });
    } catch (e) {
      // Rollback on error
      if (!mounted) return;
      setState(() {
        _optimisticClaims.remove(dish.id);
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to ${dish.isClaimed ? "unclaim" : "claim"} dish: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  void _showDishMenu(BuildContext context, PotluckDish dish) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isClaimedByMe = dish.userId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              // Dish details
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.dishName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (dish.description != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        dish.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Divider(height: 1, color: appColors.divider),

              // Actions
              ListTile(
                leading: Icon(
                  dish.isClaimed ? Icons.close : Icons.check,
                  color: appColors.textSecondary,
                ),
                title: Text(dish.isClaimed ? 'Unclaim Dish' : 'Claim Dish'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleClaim(context, dish);
                },
              ),

              if (isClaimedByMe || dish.userId == null)
                ListTile(
                  leading: Icon(Icons.delete, color: colorScheme.error),
                  title: Text(
                    'Delete Dish',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteDish(context, dish);
                  },
                ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDish(BuildContext context, PotluckDish dish) async {
    final provider = Provider.of<CalendarProvider>(context, listen: false);

    // Capture messenger and theme before async gap
    final messenger = ScaffoldMessenger.of(context);
    final successColor = context.appColors.success;
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      await provider.deletePotluckDish(_currentEvent.id, dish.id);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Dish deleted'),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete dish: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
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
