import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


//class for displaying comments in the our app
class CommentsPage extends StatefulWidget {
  final int postId;
  const CommentsPage({Key? key, required this.postId}) : super(key: key);
  @override
  _CommentsPageState createState() => _CommentsPageState();
}
class _CommentsPageState extends State<CommentsPage> {
  List<Map<String, dynamic>> _comments = [];
  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    final response = await http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/item/${widget.postId}.json'));
    if (response.statusCode == 200) {
      Map<String, dynamic> postData = jsonDecode(response.body);
      if (postData['kids'] != null) {
        List<int> commentIds = List<int>.from(postData['kids']);
        List<Map<String, dynamic>> comments = [];
        for (int id in commentIds) {
          final commentResponse = await http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json'));
          if (commentResponse.statusCode == 200) {
            Map<String, dynamic> commentData = jsonDecode(commentResponse.body);
            comments.add(commentData);
          } else {
            throw Exception('Failed to load comment $id');
          }
        }
        setState(() {
          _comments = comments;
        });
      }
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<Map<String, dynamic>> _fetchComment(int commentId) async {
    final response = await http.get(Uri.parse('https://hacker-news.firebaseio.com/v0/item/$commentId.json'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load comment $commentId');
    }
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(comment['text'] ?? ''),
          subtitle: Text('By: ${comment['by'] ?? 'Unknown'}'),
        ),
        if (comment['kids'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var kidId in comment['kids'])
                  FutureBuilder<Map<String, dynamic>>(
                    future: _fetchComment(kidId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        return _buildComment(snapshot.data!);
                      } else {
                        return SizedBox(); // Return empty container if comment is null
                      }
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: ListView.builder(
        itemCount: _comments.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildComment(_comments[index]);
        },
      ),
    );
  }
}
