import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// GDPR consent collected on first login: analytics and personalization
/// toggles, consent persisted to `profiles`, and account deletion.
class GdprConsentScreen extends StatefulWidget {
  final SupabaseClient? client;
  final VoidCallback onDone;

  const GdprConsentScreen({super.key, this.client, required this.onDone});

  @override
  State<GdprConsentScreen> createState() => _GdprConsentScreenState();
}

class _GdprConsentScreenState extends State<GdprConsentScreen> {
  bool _analytics = false;
  bool _personalization = false;
  bool _saving = false;
  String? _error;

  SupabaseClient get _client =>
      widget.client ?? Supabase.instance.client;

  Future<void> _save({required bool accepted}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        await _client.from('profiles').upsert({
          'id': userId,
          'analytics_consent': accepted && _analytics,
          'personalization_consent': accepted && _personalization,
        });
      }
      widget.onDone();
    } catch (e) {
      setState(() => _error = 'Could not save your choices: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and all workout data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
          final userId = _client.auth.currentUser?.id;
          if (userId == null) {
            setState(() => _error = 'Not signed in.');
            return;
          }
          // Server-side deletion via SECURITY DEFINER RPC so the service-role
          // admin API is never exposed to the mobile client.
          await _client.rpc('delete_own_account');
          widget.onDone();
        } catch (e) {
          setState(() => _error = 'Could not delete account: $e');
        } finally {
          if (mounted) setState(() => _saving = false);
        }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your privacy')),
        body: _saving
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'We only process what you agree to.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Analytics'),
                    subtitle: const Text(
                      'Anonymous usage statistics to improve the app.',
                    ),
                    value: _analytics,
                    onChanged: (v) => setState(() => _analytics = v),
                  ),
                  SwitchListTile(
                    title: const Text('Personalization'),
                    subtitle: const Text(
                      'Tailored workout recommendations based on your '
                      'activity.',
                    ),
                    value: _personalization,
                    onChanged: (v) =>
                        setState(() => _personalization = v),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _save(accepted: true),
                    child: const Text('Accept and continue'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _save(accepted: false),
                    child: const Text('Continue without optional consent'),
                  ),
                  const Divider(height: 32),
                  TextButton(
                    onPressed: _deleteAccount,
                    child: const Text('Delete my account and data'),
                  ),
                ],
              ),
      );
}