import 'dart:convert';
import 'package:MeezanSync/components/loading_spinner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';
import 'package:MeezanSync/components/animated_card_gradient.dart';
import 'package:MeezanSync/components/sync_section.dart';
import 'package:MeezanSync/constants.dart';
import 'package:MeezanSync/models/sura.dart';
import 'package:MeezanSync/providers/onboarding_provider.dart';
import 'package:MeezanSync/providers/theme_provider.dart';
import 'package:MeezanSync/providers/quran_data_provider.dart';
import 'package:MeezanSync/services/auth.dart';
import 'package:MeezanSync/services/push_notifications.dart';
import 'package:MeezanSync/utils/gradients.dart';
import 'package:MeezanSync/utils/utils.dart';

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

final lightShadows = [
  Shadow(
    color: Colors.white.withOpacity(0.5),
    offset: const Offset(1, 1),
    blurRadius: 2,
  ),
  Shadow(
    color: Colors.white.withOpacity(0.5),
    offset: const Offset(-1, -1),
    blurRadius: 2,
  )
];

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Sura> _suras = [];
  bool _loadedUserData = false;
  bool _isLoading = true;
  String _currentHijriDate = '';

  @override
  void initState() {
    super.initState();
    updateThemeScale(context);
    _loadSuras();

    HijriCalendar.setLocal('ar');
    final date = HijriCalendar.now();

    String month = date.getLongMonthName();
    if (month.length > 12) {
      month = date.getShortMonthName();
    }

    // '1 Ramadan, 1446'
    _currentHijriDate =
        "${month} ${toArabicNumber(date.hDay)}, ${toArabicNumber(date.hYear)}"; // date.toString();

    Future.delayed(Duration.zero, () {
      context.read<QuranDataProvider>().getVersionDetails();
    });

    Future.delayed(Duration(seconds: 1), () {
      if (!mounted) return;

      // if logged in
      AuthService().authStateChanges.listen((user) async {
        if (!mounted || user == null) return;
        if (_loadedUserData) return;

        _loadedUserData = true;

        try {

          final changes = await context.read<QuranDataProvider>().getUserStreak();
          if (!mounted) return;
          if (changes[0] != changes[1] && changes[0] == changes[1] - 1) {
            showMessage(
              "Congrats! You have increased your streak to ${changes[1]} days",
              type: AlertMessageType.success,
            );
          }
        } catch (err) {
          print("getUserStreak error: $err");
        }

        context.read<QuranDataProvider>().getBookmarks();
        context.read<QuranDataProvider>().getRecentPages();

        Future.delayed(const Duration(seconds: 5), () {
          if (!mounted) return;
          PushNotifications.init(
                  context.read<QuranDataProvider>().fcmToken ?? "")
              .then((token) {
            print("\nPushNotifications.init token: $token");
            print("\n");

            if (context.read<QuranDataProvider>().fcmToken != token) {
              context.read<QuranDataProvider>().fcmToken = token;
            }

            if (!mounted || user.uid.isEmpty) return;
            context.read<QuranDataProvider>().createOrUpdateFCMToken(token);
          });
        });
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quranData = Provider.of<QuranDataProvider>(context, listen: false);
      quranData.init();

      final onboarding =
          Provider.of<OnboardingProvider>(context, listen: false);
      onboarding.init(context); // Important for overlay access

      // Configure steps for this page
      onboarding.clearSteps(); // Clear previous steps
      onboarding.addSteps([
        OnboardingStep(
          id: "step-1",
          title: "Read Quran",
          description:
              "To read Quran, tap the table of contents to see all the suras.",
          position: TooltipPosition.left,
          targetKey: tableOfContentsKey,
        ),
        OnboardingStep(
          id: "step-2",
          title: "Bookmark",
          description:
              "To see bookmarked pages, tap the bookmark icon at the top right.",
          position: TooltipPosition.right,
          targetKey: bookmarksKey,
        ),
        OnboardingStep(
          id: "step-3",
          title: "Streak",
          description:
              "To track your reading streak, tap the streak icon to see the leader-board (coming soon)",
          position: TooltipPosition.right,
          targetKey: streaksKey,
        ),
        OnboardingStep(
          id: "step-4",
          title: "Settings",
          description:
              "To customize your reading experience, tap the settings icon at the top right.",
          position: TooltipPosition.bottom,
          targetKey: settingsKey,
        ),
        // recent pages
        OnboardingStep(
          id: "step-5",
          title: "Recent Pages",
          description:
              "The recent pages you read will appear here. Tap on the page to read it.",
          position: TooltipPosition.bottom,
          targetKey: recentPagesKey,
        ),
        // Compass
        OnboardingStep(
          id: "step-6",
          title: "Compass",
          description:
              "To find out the direction of Kaaba, tap the compass icon at the top right.",
          position: TooltipPosition.left,
          targetKey: qiblaCompassKey,
        ),
      ], "homepage_onboarding");

      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        onboarding.startTour();
      });
    });
  }

  Future<void> _loadSuras() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/quran/suras-toc.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        _suras = jsonList.map((json) => Sura.fromJson(0, json)).toList();
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
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    List<Color> colors, {
    Duration? duration,
    GlobalKey? targetKey,
  }) {
    return AnimatedGradientCard(
      colors: colors,
      duration: duration ?? const Duration(seconds: 10),
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        key: targetKey,
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('MeezanSync'),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(_currentHijriDate,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            key: settingsKey,
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingSpinner() 
          : Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 450,
                ),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SynSection(),
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
                    const SizedBox(height: 8),

                    // Recent page box
                    AnimatedGradientCard(
                      colors: GradientColors.green,
                      duration: const Duration(seconds: 26),
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
                                left: 16.0, right: 8.0, top: 12.0, bottom: 6.0),
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
                                  key: recentPagesKey,
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
                                key: recentPagesKey,
                                padding: EdgeInsets.only(
                                  left: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                          child: context.watch<QuranDataProvider>().recentPagesLoading ? const LoadingSpinner() : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: recentPages
                                      .map((recentPage) => ListTile(
                                            onTap: () => context.go(
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
                                              timeSinceReading(recentPage)
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
                            childAspectRatio: 16 / 11,
                            children: [
                        StreamBuilder<User?>(
                          stream: AuthService().authStateChanges,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                        ConnectionState.waiting || context.watch<QuranDataProvider>().userStreakLoading) {
                                      return  LoadingSpinner();
                                    }
                            return AnimatedGradientCard(
                              colors: context
                              .watch<QuranDataProvider>()
                              .userStreakWasActiveToday
                              ? GradientColors.orange
                              : GradientColors.grey,
                              duration: const Duration(seconds: 26),
                              padding: const EdgeInsets.all(16.0),
                              child: InkWell(
                                key: streaksKey,
                                onTap: snapshot.hasData
                                ? () => context.go("/leader-board")
                                : () => warnAboutLogin(context),
                                borderRadius:
                                BorderRadius.circular(16.0),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      snapshot.hasData
                                      ? context
                                      .watch<
                                      QuranDataProvider>()
                                      .userStreakDays
                                      .toString()
                                      : "0",
                                      style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        shadows: shadows,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      snapshot.hasData
                                      ? "days streak"
                                      : "Login to see your streak",
                                      style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        shadows: shadows,
                                        fontSize: snapshot.hasData
                                        ? 14
                                        : 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                              _buildMenuItem(
                                context,
                                'Table of Contents',
                                Icons.list_alt,
                                () => context.go('/table-of-contents'),
                                GradientColors.teal,
                                duration: const Duration(seconds: 26),
                                targetKey: tableOfContentsKey,
                              ),
                              _buildMenuItem(
                                context,
                                'Bookmarks',
                                Icons.bookmark,
                                () => context.go('/bookmarks'),
                                GradientColors.blue,
                                duration: const Duration(seconds: 26),
                                targetKey: bookmarksKey,
                              ),
                              _buildMenuItem(
                                context,
                                'Qibla Compass',
                                Icons.explore,
                                () => context.go('/qibla'),
                                GradientColors.purple,
                                duration: const Duration(seconds: 26),
                                targetKey: qiblaCompassKey,
                              ),
                              // _buildMenuItem(
                              //     context,
                              //     'Streak',
                              //     Icons.timer,
                              //     () => context.go('/settings'),
                              //     GradientColors.purple,
                              //     duration: const Duration(seconds: 26)),
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
                          'About MeezanSync',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ),

                    Center(
                        child: Text(
                            context.watch<QuranDataProvider>().appVersion)),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
