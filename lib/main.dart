import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/developer_home_screen.dart';
import 'screens/home/admin_home_screen.dart';
import 'screens/home/proposal_engineer_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'screens/home/sales_home_screen.dart';

Future<void> saveSessionToCache(
  String sessionId,
  bool sessionActive,
  String userId,
  String userType,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('session_id', sessionId);
  await prefs.setBool('session_active', sessionActive);
  await prefs.setString('user_id', userId);
  await prefs.setString('user_type', userType);
  debugPrint(
    '[CACHE] Saved session_id: $sessionId, session_active: $sessionActive, user_id: $userId, user_type: $userType',
  );
}

Future<void> setUserOnlineStatus(bool isOnline) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_user_online', isOnline);
  debugPrint('[CACHE] Set is_user_online: $isOnline');
}

Future<bool> getUserOnlineStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final status = prefs.getBool('is_user_online') ?? false;
  debugPrint('[CACHE] Read is_user_online: $status');
  return status;
}

Future<Map<String, dynamic>?> getSessionFromCache() async {
  final prefs = await SharedPreferences.getInstance();
  final sessionId = prefs.getString('session_id');
  final sessionActive = prefs.getBool('session_active');
  final userId = prefs.getString('user_id');
  final userType = prefs.getString('user_type');
  debugPrint(
    '[CACHE] Read session_id: $sessionId, session_active: $sessionActive, user_id: $userId, user_type: $userType',
  );
  if (sessionId != null &&
      sessionActive != null &&
      userId != null &&
      userType != null) {
    return {
      'session_id': sessionId,
      'session_active': sessionActive,
      'user_id': userId,
      'user_type': userType,
    };
  }
  return null;
}

Future<bool> validateSessionWithSupabase(
  String userId,
  String sessionId,
) async {
  final client = Supabase.instance.client;
  final user = await client
      .from('users')
      .select('session_id, session_active, user_type')
      .eq('id', userId)
      .maybeSingle();
  if (user != null &&
      user['session_id'] == sessionId &&
      user['session_active'] == true) {
    debugPrint(
      '[CACHE] Supabase users table session valid for user_id: $userId',
    );
    return true;
  }
  final devUser = await client
      .from('dev_user')
      .select('session_id, session_active, user_type')
      .eq('id', userId)
      .maybeSingle();
  if (devUser != null &&
      devUser['session_id'] == sessionId &&
      devUser['session_active'] == true) {
    debugPrint(
      '[CACHE] Supabase dev_user table session valid for user_id: $userId',
    );
    return true;
  }
  debugPrint('[CACHE] No valid session found in Supabase for user_id: $userId');
  return false;
}

Future<void> updateUserSessionActiveMCP(String userId, bool isActive) async {
  final client = Supabase.instance.client;
  final resp = await client
      .from('users')
      .update({'session_active': isActive})
      .eq('id', userId);
  debugPrint(
    '[MCP] Updated users table session_active=$isActive for user_id=$userId, response: $resp',
  );
}

Future<void> updateUserOnlineStatusMCP(String userId, bool isOnline) async {
  final client = Supabase.instance.client;
  final resp = await client
      .from('users')
      .update({'is_user_online': isOnline})
      .eq('id', userId);
  debugPrint(
    '[MCP] Updated users table is_user_online=$isOnline for user_id=$userId, response: $resp',
  );
}

Future<void> updateUserOnlineStatusByEmailMCP(
  String email,
  bool isOnline,
) async {
  final client = Supabase.instance.client;
  final resp = await client
      .from('users')
      .update({'is_user_online': isOnline})
      .eq('email', email);
  debugPrint(
    '[MCP] Updated users table is_user_online=$isOnline for email=$email, response: $resp',
  );
}

Future<void> writePrefsToProjectDir(Map<String, dynamic> data) async {
  final file = File(
    r'D:\aryesha aPP\Crm_Aryesha\crm_app\shared_preferences.json',
  );
  await file.writeAsString(jsonEncode(data));
  debugPrint('[CUSTOM_PREFS] Wrote shared_preferences.json to project dir');
}

Future<Map<String, dynamic>> readPrefsFromProjectDir() async {
  final file = File(
    r'D:\aryesha aPP\Crm_Aryesha\crm_app\shared_preferences.json',
  );
  if (await file.exists()) {
    final contents = await file.readAsString();
    debugPrint('[CUSTOM_PREFS] Read shared_preferences.json from project dir');
    return jsonDecode(contents);
  }
  return {};
}

Future<Map<String, dynamic>?> getUserBySessionId(String sessionId) async {
  final client = Supabase.instance.client;
  final user = await client
      .from('users')
      .select('id, user_type, session_active')
      .eq('session_id', sessionId)
      .maybeSingle();
  if (user != null && user['session_active'] == true) {
    debugPrint('[AUTOLOGIN] Found user in users table by session_id');
    return user;
  }
  final devUser = await client
      .from('dev_user')
      .select('id, user_type, session_active')
      .eq('session_id', sessionId)
      .maybeSingle();
  if (devUser != null && devUser['session_active'] == true) {
    debugPrint('[AUTOLOGIN] Found user in dev_user table by session_id');
    return devUser;
  }
  debugPrint('[AUTOLOGIN] No active user found by session_id');
  return null;
}

class UserHomeRemovedScreen extends StatelessWidget {
  const UserHomeRemovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'User Home Removed',
          style: TextStyle(
            color: Colors.red,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vlapmwwroraolpgyfrtg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsYXBtd3dyb3Jhb2xwZ3lmcnRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDE3NzQsImV4cCI6MjA2NzYxNzc3NH0.3nyd2GT9DD_FMFTsJyiEqAjTIH7uREQ8R-dcamXwenQ',
  );
  Widget startScreen;
  final session = await getSessionFromCache();
  if (session != null &&
      session['session_id'] != null &&
      session['session_active'] == true) {
    final user = await getUserBySessionId(session['session_id']);
    if (user != null) {
      // Route to home screen based on user_type
      if (user['user_type'] == 'Admin') {
        startScreen = const AdminHomeScreen();
      } else if (user['user_type'] == 'Developer') {
        startScreen = const DeveloperHomeScreen();
      } else if (user['user_type'] == 'Proposal Engineer') {
        startScreen = const ProposalHomeScreen();
      } else if (user['user_type'] == 'Sales') {
        startScreen = SalesHomeScreen(
          currentUserType: user['user_type'],
          currentUserEmail: user['email'] ?? '',
          currentUserId: user['id'].toString(),
        );
      } else {
        startScreen = const Center(child: Text('User Home Removed'));
      }
    } else {
      startScreen = const LoginScreen();
    }
  } else {
    startScreen = const LoginScreen();
  }
  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tobler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: startScreen,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
