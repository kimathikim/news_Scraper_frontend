import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('newsBox'); // Ensure Hive box is initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Feed',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box _newsBox;
  String _searchQuery = '';
  String? _token;

  final List<String> _topics = ['Latest News', "AI", 'Sport', 'Health'];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initHiveBox();
    _getTokenFromLocalStorage();
  }

  Future<void> _initHiveBox() async {
    _newsBox = Hive.box('newsBox'); // Already initialized in main()
  }

  Future<void> _getTokenFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      _fetchNewsFromBackend();
    } else {
      print('Token not found in local storage');
    }
  }

  Future<void> _fetchNewsForTab(int tabIndex) async {
    final category = _topics[tabIndex];
    final url = Uri.parse(
        'https://web-production-60d1.up.railway.app/data/articles?keywords=$category');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      print(response.body);
      if (response.statusCode == 200) {
        List<dynamic> articles = json.decode(response.body);
        for (var article in articles) {
          if (article['_id'] != null) {
            _newsBox.put(article['_id'], article);
          }
        }
        setState(() {});
      } else {
        print('Failed to load articles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching articles: $e');
    }
  }

  Future<void> _fetchNewsFromBackend() async {
    final url =
        Uri.parse('https://web-production-60d1.up.railway.app/data/articles');
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $_token'});
      if (response.statusCode == 200) {
        List<dynamic> articles = json.decode(response.body);
        for (var article in articles) {
          if (article['_id'] != null) {
            _newsBox.put(article['_id'], article);
          }
        }
        setState(() {});
      } else {
        print('Failed to load articles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching articles: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredArticles(int tabIndex) {
    List<Map<String, dynamic>> articles = [];
    for (var key in _newsBox.keys) {
      Map<String, dynamic> article =
          Map<String, dynamic>.from(_newsBox.get(key));
      bool matchesSearchQuery = _searchQuery.isEmpty ||
          (article['title'] ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (article['content'] ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      bool matchesSelectedTab = tabIndex == 0 ||
          (article['title'] ?? '')
              .toLowerCase()
              .contains(_topics[tabIndex].toLowerCase()) ||
          (article['summary'] ?? '')
              .toLowerCase()
              .contains(_topics[tabIndex].toLowerCase()) ||
          (article['content'] ?? '')
              .toLowerCase()
              .contains(_topics[tabIndex].toLowerCase());
      print(matchesSelectedTab);

      if (matchesSearchQuery && matchesSelectedTab) {
        articles.add(article);
      }
    }
    return articles;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _topics.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('News Feed'),
          bottom: TabBar(unselectedLabelColor: Colors.white,

            tabs: _topics.map((topic) => Tab(text: topic)).toList(),
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
              _fetchNewsForTab(index);
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search articles...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _newsBox.listenable(),
                builder: (context, Box box, _) {
                  List<Map<String, dynamic>> filteredArticles =
                      _getFilteredArticles(_selectedTabIndex);

                  if (filteredArticles.isEmpty) {
                    return const Center(child: Text('No articles found!!!!'));
                  }

                  return ListView.builder(
                    itemCount: filteredArticles.length,
                    itemBuilder: (context, index) {
                      return _buildNewsCard(filteredArticles[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _scrapeNewsFromBackend('https://www.bbc.com/news');
          },
          backgroundColor: Colors.orange,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> newsArticle) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newsArticle['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              newsArticle['summary'] ?? 'No Summary',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By ${newsArticle['author'] ?? 'Unknown'}',
                  style: const TextStyle(
                      fontSize: 14, fontStyle: FontStyle.italic),
                ),
                Text(
                  newsArticle['created_at'] ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WebViewScreen(url: newsArticle['url'] ?? ''),
                  ),
                );
              },
              child: const Text(
                'Read full article',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildNewsCard(Map<String, dynamic> newsArticle) {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     elevation: 5,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12.0),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             newsArticle['title'] ?? 'No Title',
  //             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             newsArticle['summary'] ?? 'No Summary',
  //             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
  //           ),
  //           const SizedBox(height: 12),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'By ${newsArticle['author'] ?? 'Unknown'}',
  //                 style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
  //               ),
  //               Text(
  //                 newsArticle['created_at'] ?? '',
  //                 style: TextStyle(fontSize: 14, color: Colors.grey[600]),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 8),
  //           InkWell(
  //             onTap: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) =>
  //                       WebViewScreen(url: newsArticle['url'] ?? ''),
  //                 ),
  //               );
  //             },
  //             child: Text(
  //               'Read full article',
  //               style: TextStyle(
  //                 fontSize: 16,
  //                 color: Colors.blue,
  //                 decoration: TextDecoration.underline,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  Future<void> _scrapeNewsFromBackend(String url) async {
    final scrapeUrl = Uri.parse(
        'https://web-production-60d1.up.railway.app/data/scrape?url=$url');
    try {
      final response = await http.get(
        scrapeUrl,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        List<dynamic> articles = json.decode(response.body)['data'];
        for (var article in articles) {
          _newsBox.put(article['_id'], article);
        }
        setState(() {});
      } else {
        print('Failed to scrape articles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error scraping articles: $e');
    }
  }
}

class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
