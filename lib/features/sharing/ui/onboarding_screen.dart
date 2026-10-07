import 'package:cookbook/features/sharing/data/app_preferences_store.dart';
import 'package:flutter/material.dart';

typedef CurrentTimeProvider = DateTime Function();

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.preferencesStore,
    required this.currentTimeProvider,
    required this.onCompleted,
    super.key,
  });

  final AppPreferencesStore preferencesStore;
  final CurrentTimeProvider currentTimeProvider;
  final VoidCallback onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _saving = false;
  String? _error;

  Future<void> _useLocally() async {
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.preferencesStore.save(
        AppPreferences.onboardingCompleted(widget.currentTimeProvider()),
      );
    } on AppPreferencesStoreException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _saving = false;
      });
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Your choice could not be saved. Please try again.';
        _saving = false;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
    });
    widget.onCompleted();
  }

  void _showSharingInformation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sharing is coming later'),
        content: const Text(
          'A future update will let a cookbook owner subscribe and invite '
          'family members. Sharing and purchases are not available yet.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.menu_book,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Cookbook',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keep recipes, meal plans, and shopping lists on this '
                    'device. Local use is free, works offline, and needs no '
                    'account or payment.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sharing with family is planned for a future update and '
                    'will require a subscription for the cookbook owner.',
                    textAlign: TextAlign.center,
                  ),
                  if (_error case final error?) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      key: const ValueKey<String>('onboarding-save-error'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey<String>('use-locally-action'),
                    onPressed: _saving ? null : _useLocally,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _error == null ? 'Use locally for free' : 'Retry',
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey<String>('learn-sharing-action'),
                    onPressed: _saving ? null : _showSharingInformation,
                    child: const Text('Learn about sharing'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
