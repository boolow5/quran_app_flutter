import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  DateTime? generatedAt;

  @override
  void initState() {
    super.initState();
    _loadVersionData();
    updateThemeScale(context);

    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      context.read<ThemeProvider>().setScreenSize(
            size.width,
            size.height,
            MediaQuery.sizeOf(context).width > 600,
            MediaQuery.orientationOf(context) == Orientation.landscape,
          );
    });
  }

  void _loadVersionData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/quran/page-1.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final Map<String, dynamic> metadata =
          jsonMap['metadata'] as Map<String, dynamic>;
      print("Loaded version data: $metadata");

      setState(() {
        generatedAt = DateTime.parse(metadata['generatedAt']);
      });
    } catch (e) {
      print("Error loading version data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load version date')),
        );
      }
    }
  }

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
        title: const Text('About MeezanSync'),
      ),
      body: Column(
        children: [
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
          const Text(
            'Quran App',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // _buildRow(context, 'Version',
          //     context.watch<QuranDataProvider>().appVersion),
          Text(context.watch<QuranDataProvider>().appVersion),
          const Divider(),
          SizedBox(
            width: 320,
            child: Text(
              "MeezanSync was built after I had issues with other Quran apps playing ads with music, and videos with semi-naked women while I was in the mosque. So, I had to build something that doesn't have that issue. This app was not built to make money, but to help people learn the Quran. I hope you find it useful.\n\n"
              "The Quran text data of this app is based on data from tanzil.net which is copy of the Quran text is carefully produced, highly verified and continuously monitored by a group of specialists in Tanzil Project.\t"
              "The data was last synced on ${generatedAt?.toLocal().toString()}.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const Divider(),
          _buildRow(context, 'Developed by:', 'Mahad Ahmed', onTap: () async {
            final url = Uri.parse('https://mahad.dev');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              // copy to clipboard
              await Clipboard.setData(
                  const ClipboardData(text: 'https://mahad.dev'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Copied website URL to clipboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }),
          _buildRow(context, 'Website:', 'mahad.dev', onTap: () async {
            final url = Uri.parse('https://mahad.dev');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              // copy to clipboard
              await Clipboard.setData(
                  const ClipboardData(text: 'https://mahad.dev'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Copied website URL to clipboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }),
          _buildRow(context, 'Email:', 'info@bolow.me', onTap: () async {
            final url = Uri.parse('mailto:info@bolow.me');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              // copy to clipboard
              await Clipboard.setData(
                  const ClipboardData(text: 'info@bolow.me'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Copied email to clipboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }),
          const Divider(),
          _buildRow(
              context,
              "'Copyright © ${DateTime.now().year} Bolow ICT Solutions.\nAll rights reserved.'",
              "")
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String title,
    String value, {
    VoidCallback? onTap,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: value.isEmpty ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
