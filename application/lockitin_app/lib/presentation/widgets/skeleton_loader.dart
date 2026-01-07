import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Base skeleton loader with shimmer animation
///
/// Creates a pulsing shimmer effect for loading placeholders
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: appColors.cardBackground.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder for proposal cards in list view
class ProposalCardSkeleton extends StatelessWidget {
  const ProposalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: appColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title + Status Badge
            Row(
              children: [
                // Title skeleton
                const Expanded(
                  child: SkeletonLoader(
                    height: 20,
                    borderRadius: 4,
                  ),
                ),
                const SizedBox(width: 12),
                // Status badge skeleton
                SkeletonLoader(
                  width: 80,
                  height: 24,
                  borderRadius: 8,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Metadata Row: Creator + Deadline
            Row(
              children: [
                // Creator skeleton
                SkeletonLoader(
                  width: 120,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(width: 16),
                // Deadline skeleton
                SkeletonLoader(
                  width: 100,
                  height: 16,
                  borderRadius: 4,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vote Indicator skeleton
            Row(
              children: [
                SkeletonLoader(
                  width: 90,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(width: 12),
                SkeletonLoader(
                  width: 1,
                  height: 14,
                  borderRadius: 0,
                ),
                const SizedBox(width: 12),
                SkeletonLoader(
                  width: 80,
                  height: 16,
                  borderRadius: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for group calendar grid
class GroupCalendarSkeleton extends StatelessWidget {
  const GroupCalendarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Day headers skeleton
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: List.generate(
                7,
                (index) => Expanded(
                  child: Center(
                    child: SkeletonLoader(
                      width: 20,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Calendar grid skeleton (7×6 grid)
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(2),
                  child: SkeletonLoader(
                    borderRadius: 10,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for friend list
class FriendListSkeleton extends StatelessWidget {
  const FriendListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appColors.cardBorder),
        ),
        child: Row(
          children: [
            // Avatar circle
            SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: 24,
            ),
            const SizedBox(width: 12),
            // Text lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 140,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  SkeletonLoader(
                    width: 100,
                    height: 14,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for groups list
class GroupListSkeleton extends StatelessWidget {
  const GroupListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SkeletonLoader(
          width: 48,
          height: 48,
          borderRadius: 12,
        ),
        title: SkeletonLoader(
          width: 140,
          height: 16,
          borderRadius: 4,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: SkeletonLoader(
            width: 80,
            height: 13,
            borderRadius: 4,
          ),
        ),
        trailing: SkeletonLoader(
          width: 24,
          height: 24,
          borderRadius: 12,
        ),
      ),
    );
  }
}

/// Skeleton placeholder for proposal detail screen
class ProposalDetailSkeleton extends StatelessWidget {
  const ProposalDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                SkeletonLoader(
                  width: 80,
                  height: 24,
                  borderRadius: 6,
                ),
                const SizedBox(height: 12),

                // Title
                const SkeletonLoader(
                  height: 28,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),

                // Creator info
                Row(
                  children: [
                    SkeletonLoader(
                      width: 32,
                      height: 32,
                      borderRadius: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: 120,
                            height: 16,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 4),
                          SkeletonLoader(
                            width: 80,
                            height: 14,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Deadline
                SkeletonLoader(
                  width: 150,
                  height: 32,
                  borderRadius: 8,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info section skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 100,
                  height: 20,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SkeletonLoader(
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                SkeletonLoader(
                  width: 200,
                  height: 16,
                  borderRadius: 4,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Time Options section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(
              width: 180,
              height: 20,
              borderRadius: 4,
            ),
          ),

          const SizedBox(height: 12),

          // Time option cards (3 skeletons)
          ...[1, 2, 3].map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: appColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and time
                    Row(
                      children: [
                        Expanded(
                          child: SkeletonLoader(
                            width: 150,
                            height: 18,
                            borderRadius: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Vote buttons
                    Row(
                      children: [
                        Expanded(
                          child: SkeletonLoader(
                            height: 40,
                            borderRadius: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SkeletonLoader(
                            height: 40,
                            borderRadius: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SkeletonLoader(
                            height: 40,
                            borderRadius: 8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Vote counts
                    Row(
                      children: [
                        SkeletonLoader(
                          width: 60,
                          height: 14,
                          borderRadius: 4,
                        ),
                        const SizedBox(width: 16),
                        SkeletonLoader(
                          width: 60,
                          height: 14,
                          borderRadius: 4,
                        ),
                        const SizedBox(width: 16),
                        SkeletonLoader(
                          width: 60,
                          height: 14,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
