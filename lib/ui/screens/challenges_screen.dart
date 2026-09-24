import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:fitpact/ui/screens/challenge_store.dart';

/// Home for challenges: list of rooms, create a new one (with invite
/// code) and join a friend's room by code.
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  @override
  Widget build(BuildContext context) {
    final store = ChallengeStore.instance;
    final all = [...store.all, ...store.joined];
    return Scaffold(
      appBar: AppBar(title: const Text('My challenges')),
      body: all.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 72),
                  const SizedBox(height: 12),
                  const Text('No challenges yet'),
                  const SizedBox(height: 4),
                  Text(
                    'Create a room and invite your squad!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(8),
              children: [
                for (final c in all)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(c.name),
                      subtitle: Text(
                        '${c.exerciseType} - ${c.days} days - code ${c.inviteCode}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.isMine)
                            IconButton(
                              icon: const Icon(Icons.share),
                              tooltip: 'Share invite code',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: c.inviteCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Code ${c.inviteCode} copied!'),
                                  ),
                                );
                              },
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => context.go(
                        '/leaderboard?challengeId=${c.id}',
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: _showJoinDialog,
            icon: const Icon(Icons.group_add),
            label: const Text('Join with code'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: _showCreateSheet,
            icon: const Icon(Icons.add),
            label: const Text('Create room'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join a challenge'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Invite code',
            hintText: 'e.g. AB3K9Z',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final c = ChallengeStore.instance.joinByCode(controller.text);
              Navigator.pop(context);
              if (c != null) {
                setState(() {});
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Joined ${c.name}!')),
                );
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Invalid invite code')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet() {
    final nameController = TextEditingController();
    String exercise = 'Push-ups';
    int days = 7;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create a challenge room',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Challenge name',
                  hintText: 'e.g. Morning squad',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: exercise,
                items: const [
                  DropdownMenuItem(value: 'Push-ups', child: Text('Push-ups')),
                  DropdownMenuItem(value: 'Squats', child: Text('Squats')),
                  DropdownMenuItem(value: 'Plank', child: Text('Plank')),
                  DropdownMenuItem(value: 'Burpees', child: Text('Burpees')),
                ],
                onChanged: (v) => setSheet(() => exercise = v ?? exercise),
                decoration: const InputDecoration(labelText: 'Exercise'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: days,
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 days')),
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 14, child: Text('14 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                ],
                onChanged: (v) => setSheet(() => days = v ?? days),
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final c = ChallengeStore.instance.create(
                    name: name,
                    exerciseType: exercise,
                    days: days,
                  );
                  Navigator.pop(sheetContext);
                  setState(() {});
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Room created! Invite code: ${c.inviteCode}',
                      ),
                    ),
                  );
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}