import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/developer_home_screen.dart';
import 'screens/home/admin_home_screen.dart';
import 'screens/home/user_home_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_ip_address/get_ip_address.dart';
import 'dart:developer' as developer;
import 'screens/home/proposal_engineer_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vlapmwwroraolpgyfrtg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsYXBtd3dyb3Jhb2xwZ3lmcnRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDE3NzQsImV4cCI6MjA2NzYxNzc3NH0.3nyd2GT9DD_FMFTsJyiEqAjTIH7uREQ8R-dcamXwenQ',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    developer.log('--- _checkSession called ---');
    final session = Supabase.instance.client.auth.currentSession;
    String? email;
    if (session != null) {
      email = session.user.email;
      developer.log('Supabase session exists. Email: $email');
    } else {
      developer.log('No Supabase session exists.');
    }
    String deviceType = 'unknown';
    String machineId = 'unknown';
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      deviceType = 'web';
      try {
        final ipAddress = IpAddress(type: RequestType.text);
        machineId = await ipAddress.getIpAddress();
        developer.log('Web detected. IP as machineId: $machineId');
      } catch (e) {
        machineId = 'web';
        developer.log(
          'Web detected. Failed to get IP, using fallback machineId: web',
        );
      }
    } else if (Platform.isAndroid) {
      deviceType = 'android';
      final info = await deviceInfo.androidInfo;
      machineId = info.id;
      developer.log('Android detected. machineId: $machineId');
    } else if (Platform.isIOS) {
      deviceType = 'ios';
      final info = await deviceInfo.iosInfo;
      machineId = info.identifierForVendor ?? 'unknown';
      developer.log('iOS detected. machineId: $machineId');
    } else if (Platform.isWindows) {
      deviceType = 'windows';
      final info = await deviceInfo.windowsInfo;
      machineId = info.deviceId;
      developer.log('Windows detected. machineId: $machineId');
    } else if (Platform.isMacOS) {
      deviceType = 'macos';
      final info = await deviceInfo.macOsInfo;
      machineId = info.systemGUID ?? 'unknown';
      developer.log('macOS detected. machineId: $machineId');
    }
    // 1. If session exists, use current logic
    if (session != null && email != null) {
      developer.log('Checking users table for session...');
      final userResult = await Supabase.instance.client
          .from('users')
          .select('user_type, verified')
          .eq('email', email)
          .eq('device_type', deviceType)
          .eq('machine_id', machineId)
          .eq('session_active', true)
          .maybeSingle();
      developer.log('users table result: $userResult');
      developer.log('Checking dev_user table for session...');
      final devUserResult = await Supabase.instance.client
          .from('dev_user')
          .select('user_type, verified')
          .eq('email', email)
          .eq('device_type', deviceType)
          .eq('machine_id', machineId)
          .eq('session_active', true)
          .maybeSingle();
      developer.log('dev_user table result: $devUserResult');
      final result = userResult ?? devUserResult;
      if (result != null && result['verified'] == true) {
        String userType = result['user_type'] ?? '';
        developer.log('Auto-login: $userType');
        if (userType == 'Developer') {
          setState(() => _home = const DeveloperHomeScreen());
        } else if (userType == 'Admin') {
          setState(() => _home = const AdminHomeScreen());
        } else if (userType == 'Proposal Engineer') {
          setState(() => _home = const ProposalHomeScreen());
        } else {
          setState(() => _home = const UserHomeScreen());
        }
        return;
      }
    }
    // 2. If session is null, but on web, check for active session in DB
    if (kIsWeb) {
      developer.log(
        'No Supabase session, checking DB for active web session...',
      );
      final userResult = await Supabase.instance.client
          .from('users')
          .select('user_type, verified')
          .eq('device_type', deviceType)
          .eq('machine_id', machineId)
          .eq('session_active', true)
          .maybeSingle();
      developer.log('users table result (web): $userResult');
      final devUserResult = await Supabase.instance.client
          .from('dev_user')
          .select('user_type, verified')
          .eq('device_type', deviceType)
          .eq('machine_id', machineId)
          .eq('session_active', true)
          .maybeSingle();
      developer.log('dev_user table result (web): $devUserResult');
      final result = userResult ?? devUserResult;
      if (result != null && result['verified'] == true) {
        String userType = result['user_type'] ?? '';
        developer.log('Auto-login (web, DB): $userType');
        if (userType == 'Developer') {
          setState(() => _home = const DeveloperHomeScreen());
        } else if (userType == 'Admin') {
          setState(() => _home = const AdminHomeScreen());
        } else if (userType == 'Proposal Engineer') {
          setState(() => _home = const ProposalHomeScreen());
        } else {
          setState(() => _home = const UserHomeScreen());
        }
        return;
      }
    }
    developer.log('No active session found. Showing login screen.');
    setState(() => _home = const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _home ?? const SizedBox.shrink(),
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
