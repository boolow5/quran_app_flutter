import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:MeezanSync/constants.dart';
import 'package:MeezanSync/providers/quran_data_provider.dart';
import 'package:MeezanSync/providers/theme_provider.dart';
import 'package:MeezanSync/services/auth.dart';
import 'package:MeezanSync/utils/utils.dart';

class SynSection extends StatefulWidget {
  const SynSection({super.key});

  @override
  State<SynSection> createState() => _SynSectionState();
}

class _SynSectionState extends State<SynSection> {
  @override
  void initState() {
    super.initState();

    // AuthService().authStateChanges.listen((user) {
    //   if (!mounted) return;
    //   context.read<QuranDataProvider>().setUser(user?.uid);
    // });
  }

  void _onLogout() async {
    print("_onLogout");

    // confirm logout
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => context.pop(),
          ),
          TextButton(
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await AuthService().signOut();
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  // void _onLogout() async {
  //   // crash to test crashlytics
  //
  //   bool isEnabled =
  //       await FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled;
  //   print('Crashlytics collection enabled: $isEnabled');
  //
  //   // Log something before crash
  //   FirebaseCrashlytics.instance.log('About to crash');
  //
  //   // Option 1: Force a crash
  //   FirebaseCrashlytics.instance.crash();
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    return StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return GestureDetector(
            onTap: snapshot.hasData ? _onLogout : () => context.push('/login'),
            child: LayoutBuilder(builder: (context, constraints) {
              return Container(
                height: 60,
                padding: const EdgeInsets.all(12.0),
                margin: EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: snapshot.hasData
                      ? isDark
                          ? Colors.black
                          : Colors.white
                      : Colors.red, // .withValues(alpha: 16),
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    // BoxShadow(
                    //   color: Colors.black.withOpacity(0.1),
                    //   blurRadius: 4,
                    //   offset: const Offset(0, 2),
                    // ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth * 0.75,
                      child: snapshot.hasData
                          ? Text(
                              // 'Assalamu Alaikum, ${capitalize(AuthService().currentUser?.displayName ?? AuthService().currentUser?.email?.split('@').first ?? '')}!',
                              AuthService().currentUser?.displayName != null
                                  ? 'Assalamu Alaikum, ${firstName(AuthService().currentUser?.displayName)}'
                                  : 'Assalamu Alaikum',
                            )
                          : Text(
                              'Sign in to sync bookmarks and recent pages',
                              style: TextStyle(
                                color: snapshot.hasData
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                    ),
                    const Spacer(),
                    Icon(
                      snapshot.hasData ? Icons.logout : Icons.login,
                      color: snapshot.hasData ? Colors.red : Colors.white,
                    ),
                    // snapshot.hasData
                    // ? IconButton(
                    //     icon: const Icon(Icons.logout, color: Colors.red),
                    //     onPressed: _onLogout,
                    //   )
                    // : IconButton(
                    //     icon: const Icon(Icons.login, color: Colors.green),
                    //     onPressed: ,
                    //   ),
                  ],
                ),
              );
            }),
          );
        });
  }
}
