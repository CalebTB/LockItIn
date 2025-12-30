import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/device_calendar_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../providers/settings_provider.dart';
import 'auth/login_screen.dart';

/// Profile screen for viewing and editing user profile
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      fullName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelEditing() {
    final user = context.read<AuthProvider>().currentUser;
    setState(() {
      _nameController.text = user?.fullName ?? '';
      _bioController.text = user?.bio ?? '';
      _isEditing = false;
    });
  }

  Future<void> _handleLogout() async {
    // Clear provider state BEFORE signing out to prevent data leaks
    // This ensures cached data from this user won't be visible to the next user
    context.read<FriendProvider>().reset();
    context.read<GroupProvider>().reset();

    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user data available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
          if (_isEditing && !_isSaving)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _cancelEditing,
              tooltip: 'Cancel',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: user.avatarUrl != null
                          ? Colors.grey[300]
                          : _getAvatarColor(user.email),
                      child: user.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user.avatarUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email (Read-only)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Email',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  if (_isEditing)
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Full Name',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.fullName ?? 'Not set',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: user.fullName == null ? Colors.grey : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Bio
                  if (_isEditing)
                    TextFormField(
                      controller: _bioController,
                      enabled: !_isSaving,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.info_outline),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bio',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.bio ?? 'No bio yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: user.bio == null ? Colors.grey : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Account Created
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Member Since',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(user.createdAt),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button (when editing)
                  if (_isEditing)
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),

                  // Settings Section (when not editing)
                  if (!_isEditing) ...[
                    const SizedBox(height: 32),

                    // Calendar Sync Section
                    _buildCalendarSyncSection(context, colorScheme),
                    const SizedBox(height: 24),

                    // Accessibility Section
                    Text(
                      'Accessibility',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Color-Blind Friendly Colors',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Use colors optimized for color blindness',
                          style: TextStyle(fontSize: 14),
                        ),
                        secondary: Icon(
                          Icons.palette_outlined,
                          color: colorScheme.primary,
                        ),
                        value: context.watch<SettingsProvider>().useColorBlindPalette,
                        onChanged: (value) {
                          context.read<SettingsProvider>().setColorBlindPalette(value);
                        },
                        activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Logout Button (when not editing)
                  if (!_isEditing)
                    OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getAvatarColor(String email) {
    // Generate a deterministic color from email
    int hash = 0;
    for (int i = 0; i < email.length; i++) {
      hash = email.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Use HSL to generate vibrant colors
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
  }

  Widget _buildCalendarSyncSection(BuildContext context, ColorScheme colorScheme) {
    final deviceCalendarProvider = context.watch<DeviceCalendarProvider>();
    final calendarProvider = context.watch<CalendarProvider>();
    final appColors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calendar Sync',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // Sync status card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              // Permission status / Enable sync
              ListTile(
                leading: Icon(
                  deviceCalendarProvider.hasPermission
                      ? Icons.check_circle_rounded
                      : Icons.calendar_month_outlined,
                  color: deviceCalendarProvider.hasPermission
                      ? appColors.success
                      : colorScheme.primary,
                ),
                title: Text(
                  deviceCalendarProvider.hasPermission
                      ? 'Calendar Sync Enabled'
                      : 'Enable Calendar Sync',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  deviceCalendarProvider.hasPermission
                      ? 'Your device calendar is synced with LockItIn'
                      : 'Sync your device calendar to see all events',
                  style: TextStyle(fontSize: 14, color: appColors.textMuted),
                ),
                trailing: deviceCalendarProvider.hasPermission
                    ? null
                    : FilledButton(
                        onPressed: () async {
                          await deviceCalendarProvider.requestPermission();
                          if (deviceCalendarProvider.hasPermission && mounted) {
                            await calendarProvider.refreshEvents();
                          }
                        },
                        child: const Text('Enable'),
                      ),
              ),

              // Last sync time and manual sync button
              if (deviceCalendarProvider.hasPermission) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.sync_rounded,
                    color: colorScheme.primary,
                  ),
                  title: const Text(
                    'Manual Sync',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    calendarProvider.isLoadingEvents
                        ? 'Syncing...'
                        : 'Tap to refresh events from device calendar',
                    style: TextStyle(fontSize: 14, color: appColors.textMuted),
                  ),
                  trailing: calendarProvider.isLoadingEvents
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await calendarProvider.refreshEvents();
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Calendar synced successfully!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
