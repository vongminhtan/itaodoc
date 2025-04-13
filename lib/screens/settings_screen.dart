// File: lib/screens/settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  File? readingBackgroundImage;
  final ImagePicker _picker = ImagePicker();

  // Hàm chọn ảnh từ thư viện cho nền đọc.
  Future<void> pickReadingBackgroundImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        readingBackgroundImage = File(pickedFile.path);
      });
      // Lưu đường dẫn ảnh vào SharedPreferences để phục hồi cho lần sau.
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('readingBackgroundImagePath', pickedFile.path);
    }
  }

  // Hàm load ảnh đã lưu từ SharedPreferences (nếu có)
  Future<void> loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('readingBackgroundImagePath');
    if (savedPath != null && File(savedPath).existsSync()) {
      setState(() {
        readingBackgroundImage = File(savedPath);
      });
    }
  }

  // Hàm reset ảnh nền đọc về mặc định (clear ảnh đã chọn)
  Future<void> clearReadingBackgroundImage() async {
    setState(() {
      readingBackgroundImage = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('readingBackgroundImagePath');
  }

  @override
  void initState() {
    super.initState();
    loadSavedImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cài đặt"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Đổi nền đọc",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Hiển thị ảnh nền đã chọn hoặc thông báo chưa có ảnh nếu null.
            readingBackgroundImage != null
                ? Image.file(readingBackgroundImage!, height: 200, fit: BoxFit.cover)
                : Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(child: Text("Chưa có ảnh nền")),
                  ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: pickReadingBackgroundImage,
                  child: Text("Chọn ảnh nền"),
                ),
                ElevatedButton(
                  onPressed: clearReadingBackgroundImage,
                  child: Text("Đặt mặc định"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
