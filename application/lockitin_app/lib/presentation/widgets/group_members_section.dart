import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/group_model.dart';
import '../providers/group_provider.dart';
import '../theme/sunset_coral_theme.dart';

/// Section widget showing group members with stacked avatars
///
/// Displays:
/// - Stacked avatar circles for first 5 members
/// - "+N" indicator for additional members
/// - Total member count
/// - Invite button
class GroupMembersSection extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onInvite;

  const GroupMembersSection({
    super.key,
    required this.group,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        final members = provider.selectedGroupMembers;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: SunsetCoralTheme.rose500.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // Member avatars (stacked)
              if (provider.isLoadingMembers)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SunsetCoralTheme.rose400,
                  ),
                )
              else
                SizedBox(
                  width: (members.length.clamp(0, 5) * 22.0) + 8,
                  height: 28,
                  child: Stack(
                    children: [
                      ...members.take(5).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final member = entry.value;
                        return Positioned(
                          left: index * 22.0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? null
                                  : SunsetCoralTheme.rose900.withValues(alpha: 0.8),
                              gradient: index == 0
                                  ? SunsetCoralTheme.availableGradient
                                  : null,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: SunsetCoralTheme.rose950,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                member.initials,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: index == 0
                                      ? Colors.white
                                      : SunsetCoralTheme.rose200,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              if (members.length > 5)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '+${members.length - 5}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: SunsetCoralTheme.rose300,
                    ),
                  ),
                ),

              const SizedBox(width: 8),
              Text(
                '${group.memberCount} members',
                style: const TextStyle(
                  fontSize: 11,
                  color: SunsetCoralTheme.rose300,
                ),
              ),

              const Spacer(),

              // Invite button (compact)
              GestureDetector(
                onTap: onInvite,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SunsetCoralTheme.rose500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        size: 14,
                        color: SunsetCoralTheme.rose300,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Invite',
                        style: TextStyle(
                          fontSize: 12,
                          color: SunsetCoralTheme.rose300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
