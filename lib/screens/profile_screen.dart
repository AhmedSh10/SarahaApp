import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<UserProfile?> _profileStream;
  late final Stream<UserStatus?> _statusStream;

  @override
  void initState() {
    super.initState();
    _profileStream = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.userId)
        .map((data) => data.isEmpty ? null : UserProfile.fromJson(data.first));

    _statusStream = Supabase.instance.client
        .from('user_status')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', widget.userId)
        .map((data) => data.isEmpty ? null : UserStatus.fromJson(data.first));

    _updateUserStatus(true);
  }

  Future<void> _updateUserStatus(bool isOnline) async {
    try {
      await Supabase.instance.client.from('user_status').upsert({
        'user_id': widget.userId,
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _profileStream,
        builder: (context, profileSnapshot) {
          return StreamBuilder<UserStatus?>(
            stream: _statusStream,
            builder: (context, statusSnapshot) {
              if (profileSnapshot.hasError || statusSnapshot.hasError) {
                return const Center(child: Text('Error loading profile'));
              }

              if (!profileSnapshot.hasData || !statusSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final profile = profileSnapshot.data!;
              final status = statusSnapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? Text(
                              profile.username[0].toUpperCase(),
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.username,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                status.isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.isOnline
                              ? 'Online'
                              : 'Last seen ${timeago.format(status.lastSeen)}',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _updateUserStatus(false);
    super.dispose();
  }
}