// File: lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/browser_view_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy BrowserViewModel từ Provider để truy cập lịch sử duyệt.
    final viewModel = Provider.of<BrowserViewModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Lịch Sử Duyệt"),
      ),
      body: ListView.builder(
        itemCount: viewModel.browserHistory.length,
        itemBuilder: (context, index) {
          final url = viewModel.browserHistory[index];
          return ListTile(
            title: Text(url),
            onTap: () {
              // Khi nhấn vào URL nào, đặt urlInputText và gọi loadURL, sau đó đóng màn hình lịch sử.
              viewModel.urlInputText = url;
              viewModel.loadURL();
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
