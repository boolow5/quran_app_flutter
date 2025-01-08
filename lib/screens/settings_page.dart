import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // // Font Family Selector
          // Card(
          //   child: ListTile(
          //     title: Text('Font Family',
          //         style: TextStyle(
          //           fontSize: context
          //               .watch<ThemeProvider>()
          //               .fontSize(DEFAULT_FONT_SIZE),
          //         )),
          //     subtitle: Text('Uthmanic HAFS',
          //         style: TextStyle(
          //           fontSize: context
          //               .watch<ThemeProvider>()
          //               .fontSize(DEFAULT_FONT_SIZE * 0.8),
          //         )), // Placeholder
          //     onTap: () {
          //       // TODO: Implement font family selection
          //     },
          //   ),
          // ),
          // const SizedBox(height: 16),

          // Font Size Selection
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Font Size',
                      style: TextStyle(
                        fontSize: context
                            .watch<ThemeProvider>()
                            .fontSize(DEFAULT_FONT_SIZE),
                      )),
                ),
                Slider(
                  divisions: 7,
                  min: 0.8,
                  max: 1.3,
                  value: context
                      .watch<ThemeProvider>()
                      .fontSizePercentage, // Placeholder
                  onChanged: (value) {
                    print("Slider value: $value");
                    context.read<ThemeProvider>().fontSizePercentage = value;
                    setState(() {});
                  },
                ),
                // sample text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '...'
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'
                    ' • '
                    'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: defaultFontFamily(),
                      fontSize: context.read<ThemeProvider>().fontSize(20),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dark/Light Mode Toggle
          Card(
            child: SwitchListTile(
              title: Text('Dark Mode',
                  style: TextStyle(
                    fontSize: context
                        .watch<ThemeProvider>()
                        .fontSize(DEFAULT_FONT_SIZE),
                  )),
              value: context.watch<ThemeProvider>().isDarkMode,
              onChanged: (bool value) {
                print("Toggle value: $value");
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),
        ],
      ),
    );
  }
}
