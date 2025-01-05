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
  List<Sura> _filteredSuras = [];
  String _searchText = "";
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
        _filteredSuras = _suras;
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

  void _onSearch(String value) {
    setState(() {
      _searchText = value;
      _filteredSuras = _suras
          .where((sura) =>
              sura.name.toLowerCase().contains(_searchText.toLowerCase()) ||
              sura.number == int.tryParse(_searchText) ||
              sura.englishName
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Al Quran'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.push('/');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Column(
          children: [
            // search bar
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: TextField(
                onChanged: _onSearch,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                  labelText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _filteredSuras = _suras;
                      });
                    },
                  ),
                ),
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: constraints.maxHeight * 0.8,
                    child: ListView.builder(
                      itemCount: _filteredSuras.length,
                      itemBuilder: (context, index) {
                        final sura = _filteredSuras[index];
                        return ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sura.name,
                                style: TextStyle(
                                  fontFamily: DEFAULT_FONT_FAMILY,
                                  fontSize: context
                                      .read<ThemeProvider>()
                                      .fontSize(24),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${sura.number}',
                                  style: TextStyle(
                                    fontSize: context
                                        .read<ThemeProvider>()
                                        .fontSize(16),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${sura.englishName} • ${sura.type}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          onTap: () {
                            context.push('/page/${sura.startPage}');
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
