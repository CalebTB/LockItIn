import 'package:flutter/material.dart';
import '../../../../data/models/proposal_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Information section for proposal details
///
/// Displays description, location, attendees, and group information
class ProposalInfoSection extends StatelessWidget {
  final ProposalModel proposal;
  final String groupId;

  const ProposalInfoSection({
    super.key,
    required this.proposal,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    // Only show section if there's description or location
    if ((proposal.description == null || proposal.description!.isEmpty) &&
        (proposal.location == null || proposal.location!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Description
          if (proposal.description != null && proposal.description!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.description,
              title: 'Description',
              content: Text(
                proposal.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

          if (proposal.description != null && proposal.description!.isNotEmpty)
            const SizedBox(height: 12),

          // Location
          if (proposal.location != null && proposal.location!.isNotEmpty)
            _buildInfoCard(
              context,
              icon: Icons.location_on,
              title: 'Location',
              content: Text(
                proposal.location!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  /// Build info card with icon, title, and content
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: appColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
