import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.push('/'),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Font Family Selector
          Card(
            child: ListTile(
              title: const Text('Font Family'),
              subtitle: const Text('Uthmanic HAFS'), // Placeholder
              onTap: () {
                // TODO: Implement font family selection
              },
            ),
          ),
          const SizedBox(height: 16),

          // Font Size Selection
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Font Size'),
                ),
                Slider(
                  value: 0.5, // Placeholder
                  onChanged: (value) {
                    // TODO: Implement font size change
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dark/Light Mode Toggle
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              value: context.watch<ThemeProvider>().isDarkMode,
              onChanged: (bool value) {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),
        ],
      ),
    );
  }
}
