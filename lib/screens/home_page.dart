import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/components/animated_card_gradient.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/models/sura.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/utils/gradients.dart';

final shadows = [
  Shadow(
    color: Colors.black.withOpacity(0.5),
    offset: const Offset(1, 1),
    blurRadius: 2,
  ),
  Shadow(
    color: Colors.black.withOpacity(0.5),
    offset: const Offset(-1, -1),
    blurRadius: 2,
  ),
];

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Sura> _suras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuras();
  }

  Future<void> _loadSuras() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/quran/suras-toc.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        _suras = jsonList.map((json) => Sura.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suras: $e')),
        );
      }
    }
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon,
      VoidCallback onTap, List<Color> colors) {
    return AnimatedGradientCard(
      colors: colors,
      duration: const Duration(seconds: 10),
      padding: const EdgeInsets.all(16.0),
      // margin: const EdgeInsets.all(0.0),
      // padding: const EdgeInsets.all(4.0),
      // constraints: BoxConstraints.tight(const Size(50, 50)),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(16.0),
      //   color: Theme.of(context).colorScheme.surface,
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.1),
      //       blurRadius: 4,
      //       offset: const Offset(0, 2),
      //     ),
      //   ],
      // ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
              shadows: shadows,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    shadows: shadows,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Al Quran'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App icon
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recent page box
                  AnimatedGradientCard(
                    colors: GradientColors.green,
                    duration: const Duration(seconds: 20),
                    padding: const EdgeInsets.all(0.0),
                    // padding: const EdgeInsets.all(2.0),
                    // decoration: BoxDecoration(
                    //   borderRadius: BorderRadius.circular(16.0),
                    //   color: Theme.of(context).colorScheme.surface,
                    //   boxShadow: [
                    //     BoxShadow(
                    //       color: Colors.black.withOpacity(0.1),
                    //       blurRadius: 4,
                    //       offset: const Offset(0, 2),
                    //     ),
                    //   ],
                    // ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 12.0, right: 8.0, top: 12.0, bottom: 6.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recent',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // const SizedBox(height: 4),
                        Consumer<QuranDataProvider>(
                          builder: (context, quranData, child) {
                            final recentPages = quranData.currentRecentPages;
                            if (recentPages.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                                child: Text(
                                  'No recent pages',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                              );
                            }
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: recentPages
                                    .map((recentPage) => ListTile(
                                          onTap: () => context.push(
                                            '/page/${recentPage.pageNumber}',
                                          ),
                                          dense: true,
                                          leading: Text(
                                              "Page ${recentPage.pageNumber}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium),
                                          title: Text(
                                            recentPage.suraName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          trailing: Text(
                                            quranData
                                                .timeSinceReading(recentPage)
                                                .toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Menu grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            constraints.maxWidth > 600 ? 3 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12.0,
                          crossAxisSpacing: 12.0,
                          children: [
                            _buildMenuItem(
                              context,
                              'Table of Contents',
                              Icons.list_alt,
                              () => context.push('/table-of-contents'),
                              GradientColors.teal,
                            ),
                            _buildMenuItem(
                              context,
                              'Bookmarks',
                              Icons.bookmark,
                              () => context.push('/bookmarks'),
                              GradientColors.blue,
                            ),
                            _buildMenuItem(
                              context,
                              'Qibla Compass',
                              Icons.explore,
                              () => context.push('/qibla'),
                              GradientColors.orange,
                            ),
                            _buildMenuItem(
                              context,
                              'Settings',
                              Icons.settings,
                              () => context.push('/settings'),
                              GradientColors.purple,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  Center(
                    child: GestureDetector(
                      onTap: () {
                        context.push('/about');
                      },
                      child: Text(
                        'About Al Quran',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
