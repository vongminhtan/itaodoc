// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'content_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nội dung chính của HomeScreen: hiển thị ContentScreen
      body: const ContentScreen(),
      // Drawer cho phép người dùng chuyển qua các màn hình khác.
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header của Drawer với tiêu đề
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                "Menu",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
            // Mục "Lịch sử duyệt" cho phép chuyển sang HistoryScreen
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Lịch sử duyệt"),
              onTap: () {
                Navigator.pop(context); // đóng Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
            // Mục "Cài đặt" cho phép chuyển sang SettingsScreen
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Cài đặt"),
              onTap: () {
                Navigator.pop(context); // đóng Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
