import 'package:flutter/material.dart';
import 'package:hacker_news/main.dart';
import 'package:http/http.dart' as http;

//there is realization of possibility to login to the website
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  //getting url
  Future<void> login() async {
    final url = Uri.parse('https://news.ycombinator.com/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'acct': usernameController.text,
        'pw': passwordController.text,
        'goto': 'https://news.ycombinator.com/',
      },
    );

    if (response.statusCode == 302) {
      // Login successful, cookies are in response.headers['set-cookie']
      print('Login successful');
      print('Cookies: ${response.headers['set-cookie']}');
 // Navigate to the home page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage(username: usernameController.text)),
      );
  
      } else {
       // Login failed, show alert
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Login Failed"),
          content: Text("Incorrect username or password. Please try again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}

  //login page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: Text('Hacker News Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 12.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}