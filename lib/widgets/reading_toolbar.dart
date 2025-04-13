// File: lib/widgets/reading_toolbar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/browser_view_model.dart';

class ReadingToolbar extends StatelessWidget {
  final TextEditingController urlController;

  const ReadingToolbar({Key? key, required this.urlController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy BrowserViewModel từ Provider để truy cập trạng thái và hàm điều khiển.
    final viewModel = Provider.of<BrowserViewModel>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Nút Back: chuyển sang segment trước nếu có.
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: viewModel.currentIndex > 0 ? viewModel.goBack : null,
          ),
          // Nút Forward: chuyển sang segment sau nếu có.
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: viewModel.currentIndex < viewModel.segments.length - 1 ? viewModel.goNext : null,
          ),
          // Ô nhập URL cho phép người dùng nhập địa chỉ web.
          Expanded(
            child: TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: "Nhập địa chỉ web",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                viewModel.urlInputText = value;
                viewModel.loadURL();
              },
            ),
          ),
          SizedBox(width: 8),
          // Nút "Dán và dứt" để lấy nội dung từ Clipboard (hoặc từ ô nhập) và tải trang.
          ElevatedButton(
            child: Text("Dán và dứt"),
            onPressed: () {
              viewModel.urlInputText = urlController.text;
              viewModel.loadURL();
            },
          ),
          SizedBox(width: 8),
          // Nút Reload: tải lại URL hiện tại.
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: viewModel.refresh,
          ),
          // Bạn có thể bổ sung thêm các nút (ví dụ: nút mở lịch sử) tại đây.
        ],
      ),
    );
  }
}
