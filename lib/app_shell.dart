import 'package:flutter/material.dart';

// الشاشات
//import 'screens/home/home_tab.dart';
import 'screens/agents/agents_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/account/account_screen.dart';

class AppShell extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;
  const AppShell({super.key, required this.user, required this.token});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _titles = const [
    'عقارات الشمال',
    'الفئات',
    'الوكلاء',
    'حسابي',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      // HomeTab(user: widget.user, token: widget.token),
      CategoriesScreen(token: widget.token),
      AgentsScreen(token: widget.token),
      AccountScreen(user: widget.user, token: widget.token),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index]),
          backgroundColor: const Color(0xFF003366),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {},
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'about', child: Text('من نحن')),
                PopupMenuItem(value: 'blog', child: Text('المدونة')),
                PopupMenuItem(value: 'team', child: Text('الفريق')),
                PopupMenuItem(value: 'pricing', child: Text('الأسعار')),
              ],
            ),
          ],
        ),
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'الفئات',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'الوكلاء',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}
