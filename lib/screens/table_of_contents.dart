import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/models/sura.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';

class TableOfContents extends StatefulWidget {
  const TableOfContents({super.key});

  @override
  State<TableOfContents> createState() => _TableOfContentsState();
}

class _TableOfContentsState extends State<TableOfContents> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Quran'),
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
          : ListView.builder(
              itemCount: _suras.length,
              itemBuilder: (context, index) {
                final sura = _suras[index];
                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sura.name,
                        style: TextStyle(
                          fontFamily: DEFAULT_FONT_FAMILY,
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${sura.number}',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${sura.englishName} • ${sura.type}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    context.push('/page/${sura.startPage}');
                  },
                );
              },
            ),
    );
  }
}
