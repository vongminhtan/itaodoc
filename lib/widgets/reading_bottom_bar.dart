// File: lib/widgets/reading_bottom_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/browser_view_model.dart';

class ReadingBottomBar extends StatelessWidget {
  const ReadingBottomBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy BrowserViewModel để truy cập chỉ số và danh sách segment.
    final viewModel = Provider.of<BrowserViewModel>(context);

    return Container(
      color: Colors.white.withOpacity(0.8),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nút chuyển sang segment trước đó.
          IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: viewModel.currentIndex > 0 ? viewModel.goBack : null,
          ),
          const SizedBox(width: 16.0),
          // Hiển thị chỉ số hiện tại dạng "trang hiện tại / tổng số trang".
          Text(
            "${viewModel.currentIndex + 1} / ${viewModel.segments.isNotEmpty ? viewModel.segments.length : 0}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 16.0),
          // Nút chuyển sang segment kế tiếp.
          IconButton(
            icon: Icon(Icons.arrow_forward_ios),
            onPressed: viewModel.currentIndex < viewModel.segments.length - 1 ? viewModel.goNext : null,
          ),
        ],
      ),
    );
  }
}
