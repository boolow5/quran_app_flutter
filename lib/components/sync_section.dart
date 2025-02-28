import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/services/auth.dart';
import 'package:quran_app_flutter/utils/utils.dart';

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

  void _onLogin() {
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
            onTap: snapshot.hasData ? _onLogin : () => context.push('/login'),
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
                    //     onPressed: _onLogin,
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
