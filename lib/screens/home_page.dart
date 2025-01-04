import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/models/sura.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';

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

  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
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
                  const SizedBox(height: 24),

                  // Recent page box
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            Text(
                              'Recent',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Consumer<QuranDataProvider>(
                          builder: (context, quranData, child) {
                            final recentPage = quranData.currentRecentPage;
                            if (recentPage == null) {
                              return Text(
                                'No recent pages',
                                style: Theme.of(context).textTheme.bodyLarge,
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Page ${recentPage.pageNumber} - ${recentPage.suraName}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      quranData.getReadingDuration(recentPage),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                    Text(
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
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            constraints.maxWidth > 600 ? 3 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16.0,
                          crossAxisSpacing: 16.0,
                          children: [
                            _buildMenuItem(
                              context,
                              'Table of Contents',
                              Icons.list_alt,
                              () => context.push('/table-of-contents'),
                            ),
                            _buildMenuItem(
                              context,
                              'Bookmarks',
                              Icons.bookmark,
                              () => context.push('/bookmarks'),
                            ),
                            _buildMenuItem(
                              context,
                              'Qibla Compass',
                              Icons.explore,
                              () => context.push('/qibla'),
                            ),
                            _buildMenuItem(
                              context,
                              'Settings',
                              Icons.settings,
                              () => context.push('/settings'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
