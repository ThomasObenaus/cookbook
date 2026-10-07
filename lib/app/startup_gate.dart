import 'package:cookbook/features/sharing/data/app_preferences_store.dart';
import 'package:cookbook/features/sharing/ui/onboarding_screen.dart';
import 'package:flutter/material.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({
    required this.initialPreferences,
    required this.preferencesStore,
    required this.currentTimeProvider,
    required this.cookbook,
    super.key,
  });

  final AppPreferences initialPreferences;
  final AppPreferencesStore preferencesStore;
  final CurrentTimeProvider currentTimeProvider;
  final Widget cookbook;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late bool _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _onboardingCompleted = widget.initialPreferences.onboardingCompleted;
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingCompleted) {
      return widget.cookbook;
    }
    return OnboardingScreen(
      preferencesStore: widget.preferencesStore,
      currentTimeProvider: widget.currentTimeProvider,
      onCompleted: () {
        setState(() {
          _onboardingCompleted = true;
        });
      },
    );
  }
}
