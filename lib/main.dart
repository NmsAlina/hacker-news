import 'package:flutter/material.dart';
import 'package:hacker_news/comments.dart';
import 'package:hacker_news/hacker_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hacker News',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        // '/login': (context) => LoginPage(),
      },
    );
  }
}

//start with home page
class HomePage extends StatefulWidget {
  final String? username;
  const HomePage({Key? key, this.username}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _posts = [];
  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  void upvotePost(int postId) {
    if (widget.username != null) {
      // User is logged in, proceed with upvote
      String auth = 'your_auth_token_here'; // Replace with the actual auth token
      String url = 'https://news.ycombinator.com/vote?id=$postId&how=up&auth=$auth&goto=news&js=t';
      // Perform the upvote request
      http.get(Uri.parse(url)).then((response) {
        if (response.statusCode == 200) {
          // Upvote successful
          print('Upvote successful');
          setState(() {
            // Update the score in the UI
            // _posts.firstWhere((post) => post['id'] == postId)['score']++;
          });
        } else {
          // Upvote failed
          print('Upvote failed');
        }
      }).catchError((error) {
        print('Error upvoting: $error');
      });
    } else {
      // User is not logged in, navigate to the login page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/topstories.json'));
    if (response.statusCode == 200) {
      List<dynamic> postIds = jsonDecode(response.body);
      List<Map<String, dynamic>> posts = [];
      for (int i = 0; i < 10; i++) {
        final postResponse = await http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/item/${postIds[i]}.json'));
        if (postResponse.statusCode == 200) {
          Map<String, dynamic> postData = jsonDecode(postResponse.body);
          posts.add(postData);
        } else {
          throw Exception('Failed to load post ${postIds[i]}');
        }
      }
      setState(() {
        _posts = posts;
      });
    } else {
      throw Exception('Failed to load post IDs');
    }
  }

  void logout() {
    // Clear the username
    // Navigate back to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  //design of home page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        automaticallyImplyLeading: false,
        title: Text('Hacker News'),
        actions: [
          if (widget.username != null)
            IconButton(
              onPressed: logout,
              icon: Icon(Icons.logout),
            )
          else
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              icon: Icon(Icons.login),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.username != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Welcome, ${widget.username}!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (BuildContext context, int index) {
                // Convert Unix timestamp to DateTime
                DateTime postDateTime = DateTime.fromMillisecondsSinceEpoch(_posts[index]['time'] * 1000);
                // Format only the time part of DateTime
                String formattedTime = DateFormat.yMd().format(postDateTime) + ' ' + DateFormat.Hm().format(postDateTime);
                return Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        _posts[index]['title'],
                        style: TextStyle(color: Colors.black), // Specify text color
                      ),
                      subtitle: Text(
                        'By: ${_posts[index]['by']} at $formattedTime',
                        style: TextStyle(color: Colors.grey), // Specify text color
                      ),

                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => upvotePost(_posts[index]['id']),
                            child: Icon(
                              Icons.arrow_upward,
                              size: 18,
                              color: Colors.cyan, // Specify the color of the icon
                            ),
                          ),

                          Text(
                            '${_posts[index]['score']} votes',
                            style: TextStyle(color: Colors.indigoAccent), // Specify text color
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommentsPage(postId: _posts[index]['id']), // Navigate to CommentsPage
                                ),
                              );
                            },
                            child: Text(
                              '${_posts[index]['descendants']} comments',
                              style: TextStyle(color: Colors.deepPurpleAccent), // Specify text color
                            ),
                          )
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostPage(post: _posts[index]),
                          ),
                        );
                      },
                    ),
                    Divider(), // Add a Divider after each ListTile
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//class for displaying posts in the our app
class PostPage extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostPage({Key? key, required this.post}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post['title']),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'By: ${post['by']}',
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            child: WebView(
              initialUrl: post['url'],
            ),
          ),
        ],
      ),
    );
  }
}

