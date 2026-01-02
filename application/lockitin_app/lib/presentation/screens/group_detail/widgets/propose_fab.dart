import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating action button for proposing a new event
class ProposeFAB extends StatelessWidget {
  final String groupName;
  final VoidCallback onPressed;

  const ProposeFAB({
    super.key,
    required this.groupName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Propose a new event for $groupName',
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        tooltip: 'Propose a new event',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Propose',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
