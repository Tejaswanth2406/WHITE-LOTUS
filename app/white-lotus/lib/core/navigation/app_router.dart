import 'package:flutter/material.dart';

import '../../features/vault/vault_screen.dart' as feature_vault;

class AppRoute {
  static const dashboard = '/';
  static const vault = '/vault';
  static const search = '/search';
  static const devices = '/devices';
  static const settings = '/settings';
}

class AppRouter {
  static PageRoute<T> routeFor<T>(String name) {
    final screen = switch (name) {
      AppRoute.vault => const feature_vault.VaultScreen(),
      AppRoute.search => const SearchScreen(),
      AppRoute.devices => const DevicesScreen(),
      AppRoute.settings => const SettingsScreen(),
      _ => const DashboardScreen(),
    };

    return MaterialPageRoute<T>(builder: (_) => screen);
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Command Center')),
      body: const Center(child: Text('Dashboard placeholder')),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const Center(child: Text('Search placeholder')),
    );
  }
}

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: const Center(child: Text('Devices placeholder')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings placeholder')),
    );
  }
}
