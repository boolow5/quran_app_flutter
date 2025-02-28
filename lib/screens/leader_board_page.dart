import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/leader_board_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/utils/utils.dart';

class LeaderBoardPage extends StatefulWidget {
  const LeaderBoardPage({super.key});

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  @override
  void initState() {
    super.initState();
    updateThemeScale(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Leader Board'),
        centerTitle: true,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: context.watch<LeaderBoardProvider>().leaderBoard.isEmpty
          ? const Center(child: Text('Leader board is coming soon!'))
          : LayoutBuilder(builder: (context, constraints) {
              return Column(
                children: [
                  SizedBox(
                    height: constraints.maxHeight - 48,
                    child: ListView.builder(
                      itemCount: context
                          .watch<LeaderBoardProvider>()
                          .leaderBoard
                          .length,
                      itemBuilder: (context, index) {
                        final leaderBoard = context
                            .watch<LeaderBoardProvider>()
                            .leaderBoard[index];
                        final timeSince = "";
                        // timeSinceReading(leaderBoard, start: true);

                        return ListTile(
                          title: Text(
                            leaderBoard.name,
                            style: TextStyle(
                              fontFamily: defaultFontFamily(),
                              fontSize:
                                  context.read<ThemeProvider>().fontSize(24),
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          subtitle: Text(
                            "${leaderBoard.score}",
                            style: TextStyle(
                              fontSize:
                                  context.read<ThemeProvider>().fontSize(16),
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            timeSince.toString(),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          onTap: () {
                            final path = '/profile/${leaderBoard.userID}';
                            print("Pushing $path");
                            // context.push(path);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
    );
  }
}
