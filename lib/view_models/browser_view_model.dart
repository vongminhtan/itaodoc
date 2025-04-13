// File: lib/view_models/browser_view_model.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/browser_segment.dart';
import '../utils/html_utils.dart';
import '../utils/advanced_html_parser.dart';

class BrowserViewModel extends ChangeNotifier {
  List<BrowserSegment> segments = [];
  int currentIndex = 0;
  String currentURL = "";
  String urlInputText = "";
  bool isLoading = false;
  String? errorMessage;
  List<Map<String, String>> browserHistory = [];
  
  // Added properties from reference project
  Color _textColor = Colors.black; // Default text color
  double _readingBackgroundOpacity = 0.8; // Default opacity
  
  // Constructor - load saved history
  BrowserViewModel() {
    loadSavedHistory();
  }

  // Getters for new properties
  Color get textColor => _textColor;
  double get readingBackgroundOpacity => _readingBackgroundOpacity;

  // Change text color with saving preference
  void changeTextColor(Color newColor) {
    _textColor = newColor;
    notifyListeners();
    _saveTextColorPreference(newColor);
  }
  
  // Save text color preference
  Future<void> _saveTextColorPreference(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('text_color', color.value);
  }
  
  // Load saved text color preference
  Future<void> loadSavedTextColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('text_color');
    if (colorValue != null) {
      _textColor = Color(colorValue);
      notifyListeners();
    }
  }

  // Change reading background opacity
  void changeReadingBackgroundOpacity(double opacity) {
    _readingBackgroundOpacity = opacity;
    notifyListeners();
    _saveOpacityPreference(opacity);
  }
  
  // Save opacity preference
  Future<void> _saveOpacityPreference(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reading_bg_opacity', opacity);
  }
  
  // Load saved opacity preference
  Future<void> loadSavedOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    final opacity = prefs.getDouble('reading_bg_opacity');
    if (opacity != null) {
      _readingBackgroundOpacity = opacity;
      notifyListeners();
    }
  }

  // Save browser history to SharedPreferences
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = browserHistory.map((item) => jsonEncode(item)).toList();
      await prefs.setStringList('browser_history', historyJson);
    } catch (e) {
      print('Error saving browser history: $e');
    }
  }

  // Load browser history from SharedPreferences
  Future<void> loadSavedHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('browser_history');
      if (historyJson != null && historyJson.isNotEmpty) {
        browserHistory = historyJson
            .map((item) => Map<String, String>.from(jsonDecode(item)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading browser history: $e');
    }
  }

  // Hàm tải URL: sử dụng http để lấy HTML và sau đó parse nội dung.
  Future<void> loadURL() async {
    errorMessage = null;
    String urlString = urlInputText.trim();
    if (urlString.isEmpty) {
      // Nếu không nhập gì thì xóa segments và reset trạng thái.
      segments = [];
      currentURL = "";
      isLoading = false;
      notifyListeners();
      return;
    }

    // Nếu URL chưa có http/https, tự động thêm vào.
    if (!urlString.startsWith("http://") && !urlString.startsWith("https://")) {
      urlString = "https://" + urlString;
      urlInputText = urlString;
    }

    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      errorMessage = "URL không hợp lệ";
      notifyListeners();
      return;
    }

    isLoading = true;
    currentURL = urlString;

    // Manage history
    if (browserHistory.isEmpty || !browserHistory.any((item) => item['url'] == urlString)) {
      browserHistory.add({'url': urlString, 'title': ''});
      if (browserHistory.length > 100) {
        browserHistory.removeAt(0);
      }
      // Save history after updating
      _saveHistory();
    }

    // Reset lại segments và chỉ số hiện tại.
    segments = [];
    currentIndex = 0;
    notifyListeners();

    try {
      // Gửi yêu cầu HTTP để lấy nội dung HTML với headers phù hợp
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml',
          'Accept-Charset': 'UTF-8',
          'User-Agent': 'Mozilla/5.0 (compatible; iTaoDoc/1.0)'
        }
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200 || response.body.isEmpty) {
        errorMessage = "Trang không có dữ liệu hoặc có lỗi tải trang.";
        isLoading = false;
        notifyListeners();
        return;
      }
      
      // Lấy nội dung HTML dạng chuỗi và đảm bảo sử dụng encoding UTF-8 cho tiếng Việt
      String htmlContent = utf8.decode(response.bodyBytes);
      parseHTMLContent(htmlContent, uri);
    } catch (e) {
      errorMessage = "Lỗi tải HTML: $e";
      isLoading = false;
      notifyListeners();
    }
  }

  // Hàm parseHTMLContent: xử lý HTML để lấy tiêu đề, văn bản thuần và hình ảnh.
  void parseHTMLContent(String htmlContent, Uri baseUri) {
    try {
      // Extract title using HtmlUtils
      String title = HtmlUtils.extractTitle(htmlContent);
      
      // Update the title in history for the current URL
      for (int i = 0; i < browserHistory.length; i++) {
        if (browserHistory[i]['url'] == currentURL) {
          browserHistory[i]['title'] = title;
          // Save history after updating title
          _saveHistory();
          break;
        }
      }

      // Áp dụng thuật toán phân tích nâng cao từ AdvancedHtmlParser
      List<String> textSegments = AdvancedHtmlParser.parseHtml(htmlContent);
      
      // Tạo các đoạn văn bản
      List<BrowserSegment> contentSegments = [];
      
      // Nếu có tiêu đề, thêm vào đầu tiên
      if (title.isNotEmpty) {
        contentSegments.add(BrowserSegment.text(title));
      }
      
      // Thêm các đoạn văn bản đã xử lý
      for (String text in textSegments) {
        // Bỏ qua nếu đoạn văn bản giống tiêu đề hoặc quá ngắn
        if (text != title && text.length > 3) {
          contentSegments.add(BrowserSegment.text(text));
        }
      }

      // Lấy URL hình ảnh
      List<String> imageUrls = HtmlUtils.extractImages(htmlContent, baseUri);
      List<BrowserSegment> imageSegments = imageUrls.map((url) => BrowserSegment.image(url)).toList();

      // Xen kẽ văn bản và hình ảnh
      List<BrowserSegment> combined = [];
      
      // Thêm tất cả đoạn văn bản trước
      combined.addAll(contentSegments);
      
      // Cố gắng phân phối hình ảnh hợp lý trong nội dung
      if (imageSegments.isNotEmpty && combined.length > 1) {
        List<BrowserSegment> finalCombined = [];
        
        // Giữ tiêu đề là đoạn đầu tiên nếu có
        finalCombined.add(combined.first);
        
        // Đặt hình ảnh đều đặn trong nội dung
        int textCount = combined.length - 1; // Không tính tiêu đề
        int imgCount = imageSegments.length;
        
        // Tính khoảng cách để đặt hình ảnh
        int interval = textCount > imgCount ? textCount ~/ imgCount : 1;
        
        int imgIndex = 0;
        for (int i = 1; i < combined.length; i++) {
          finalCombined.add(combined[i]);
          
          // Sau mỗi khoảng cách, chèn một hình ảnh nếu có
          if (i % interval == 0 && imgIndex < imageSegments.length) {
            finalCombined.add(imageSegments[imgIndex]);
            imgIndex++;
          }
        }
        
        // Thêm các hình ảnh còn lại vào cuối
        while (imgIndex < imageSegments.length) {
          finalCombined.add(imageSegments[imgIndex]);
          imgIndex++;
        }
        
        combined = finalCombined;
      }

      // Cập nhật trạng thái
      segments = combined;
      isLoading = false;
      errorMessage = null;
      currentIndex = 0;
      notifyListeners();
    } catch (e) {
      errorMessage = "Lỗi xử lý HTML: $e";
      isLoading = false;
      notifyListeners();
    }
  }

  // Hàm di chuyển đến segment tiếp theo.
  void goNext() {
    if (currentIndex < segments.length - 1) {
      currentIndex++;
      notifyListeners();
    }
  }

  // Hàm di chuyển đến segment trước đó.
  void goBack() {
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
    }
  }

  // Hàm làm mới nội dung bằng cách tải lại URL.
  void refresh() {
    loadURL();
  }
  
  // Jump to specific page
  void jumpToPage(int index) {
    if (index >= 0 && index < segments.length) {
      currentIndex = index;
      notifyListeners();
    }
  }
}
