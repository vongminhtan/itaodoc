// File: lib/widgets/background_view.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BackgroundView extends StatefulWidget {
  // Nếu có, sẽ hiển thị ảnh nền do người dùng chọn (custom background image).
  final File? customBackgroundImage;
  // Nếu không có ảnh custom, hiển thị WebView với URL được truyền vào.
  final String? webBackgroundUrl;

  const BackgroundView({
    Key? key,
    this.customBackgroundImage,
    this.webBackgroundUrl,
  }) : super(key: key);

  @override
  _BackgroundViewState createState() => _BackgroundViewState();
}

class _BackgroundViewState extends State<BackgroundView> {
  @override
  void initState() {
    super.initState();
    // Đối với Android, cần thiết lập WebView.platform nếu sử dụng webview_flutter.
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu có ảnh custom, ưu tiên hiển thị ảnh đó với hiệu ứng blur.
    if (widget.customBackgroundImage != null) {
      return Positioned.fill(
        child: Stack(
          children: [
            Image.file(
              widget.customBackgroundImage!,
              fit: BoxFit.cover,
            ),
            // Áp dụng hiệu ứng blur sử dụng BackdropFilter.
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0), // Opacity 0 để chỉ dùng hiệu ứng blur.
              ),
            ),
          ],
        ),
      );
    }
    // Nếu không có ảnh custom nhưng có URL của WebView, sử dụng WebView với hiệu ứng mờ.
    else if (widget.webBackgroundUrl != null && widget.webBackgroundUrl!.isNotEmpty) {
      return Positioned.fill(
        child: Stack(
          children: [
            WebView(
              initialUrl: widget.webBackgroundUrl,
              javascriptMode: JavascriptMode.unrestricted,
            ),
            // Áp dụng hiệu ứng blur và thêm lớp phủ nhẹ (overlay) để giảm độ sắc nét.
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    }
    // Fallback: nếu không có dữ liệu nào, hiển thị màu nền đơn giản.
    else {
      return Positioned.fill(
        child: Container(
          color: Colors.grey.shade300,
        ),
      );
    }
  }
}
