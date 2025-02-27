import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return LayoutBuilder(builder: (context, constraints) {
            return Container(
              height: 55,
              padding: const EdgeInsets.all(8.0),
              margin: EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: DEFAULT_PAGE_BG_COLOR,
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
                        : const Text(
                            'Sign in to sync bookmarks and recent pages'),
                  ),
                  const Spacer(),
                  snapshot.hasData
                      ? IconButton(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          onPressed: () {
                            // confirm logout
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text(
                                    'Are you sure you want to logout?'),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () => context.pop(),
                                  ),
                                  TextButton(
                                    child: const Text('Logout',
                                        style: TextStyle(color: Colors.red)),
                                    onPressed: () async {
                                      await AuthService().signOut();
                                      context.pop();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.login, color: Colors.green),
                          onPressed: () => context.push('/login'),
                        ),
                ],
              ),
            );
          });
        });
  }
}
