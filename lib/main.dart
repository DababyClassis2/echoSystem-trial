import 'package:flutter/material.dart';

void main() {
  runApp(const EchoSystemApp());
}

class EchoSystemApp extends StatelessWidget {
  const EchoSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'echoSystem',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EchoHomePage(),
    );
  }
}

class EchoHomePage extends StatefulWidget {
  const EchoHomePage({super.key});

  @override
  State<EchoHomePage> createState() => _EchoHomePageState();
}

class _EchoHomePageState extends State<EchoHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    Center(child: Text('Tab 1: Home\n\nThis is the main hub of echoSystem, where you can initiate local sharing.\n')),
    Center(child: Text('Tab 2: Files\n\nManage and view all your shared local files here.\n')),
    Center(child: Text('Tab 3: Devices\n\nSee all connected devices in your local echoSystem network.\n')),
    Center(child: Text('Tab 4: Profile\n\nManage your local echoSystem profile and settings.\n')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('echoSystem')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('echoSystem Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(title: const Text('Update'), onTap: () {}),
            ListTile(title: const Text('Settings'), onTap: () {}),
            ListTile(title: const Text('Logs'), onTap: () {}),
            ListTile(title: const Text('Themes'), onTap: () {}),
            ListTile(title: const Text('Exit'), onTap: () {}),
          ],
        ),
      ),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
