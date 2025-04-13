import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

/// Simple StringBuilder class for Dart (since Dart doesn't have one built-in)
class StringBuilder {
  final StringBuffer _buffer = StringBuffer();
  
  void write(String s) {
    _buffer.write(s);
  }
  
  @override
  String toString() {
    return _buffer.toString();
  }
}

/// Lớp tiện ích triển khai thuật toán xử lý HTML nâng cao từ test.py
class AdvancedHtmlParser {
  /// Ngưỡng số từ để xác định câu dài
  static const int wordThreshold = 25;

  /// Phân tích HTML và trả về danh sách các đoạn văn bản đã được xử lý
  static List<String> parseHtml(String htmlContent) {
    // Parse HTML
    var document = html.parse(htmlContent);
    
    // Xóa các thẻ script và style
    document.querySelectorAll('script').forEach((element) => element.remove());
    document.querySelectorAll('style').forEach((element) => element.remove());
    
    // Lấy ra thẻ body hoặc sử dụng toàn bộ document nếu không có body
    var bodyElement = document.body ?? document;
    
    // Xử lý document
    List<String> segments = [];
    if (bodyElement is Element) {
      processElement(bodyElement, segments);
    } else {
      // Xử lý trực tiếp các phần tử con của body nếu bodyElement không phải Element
      for (var child in bodyElement.children) {
        processElement(child, segments);
      }
    }
    
    // Lọc và chuẩn hóa các đoạn văn bản
    segments = segments
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    
    return segments;
  }
  
  /// Chuẩn hóa text: bỏ khoảng trắng thừa nhưng giữ nguyên xuống dòng
  static String normalizeText(String text) {
    if (text.isEmpty) return text;
    
    // Giữ lại xuống dòng, chỉ chuẩn hoá khoảng trắng trong mỗi dòng
    List<String> lines = text.split('\n');
    List<String> normalizedLines = [];
    
    for (String line in lines) {
      // Thay thế nhiều khoảng trắng liên tiếp bằng một khoảng trắng
      String normalizedLine = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalizedLine.isNotEmpty) {
        normalizedLines.add(normalizedLine);
      }
    }
    
    // Nối các dòng lại với xuống dòng
    return normalizedLines.join('\n');
  }
  
  /// Xử lý đệ quy một phần tử HTML, tương tự như process_element trong test.py
  static void processElement(Element element, List<String> segments, {Element? parentTag}) {
    // Xử lý các thẻ tiêu đề h1-h6
    if (element.localName != null && 
        RegExp(r'^h[1-6]$').hasMatch(element.localName!)) {
      String text = normalizeText(element.text);
      if (text.isNotEmpty) {
        segments.add(text);
        return;
      }
    }
    
    // Xử lý các thẻ đặc biệt
    switch (element.localName) {
      case 'tr':
      case 'blockquote':
        String text = normalizeText(element.text);
        if (text.isNotEmpty) {
          if (element.localName == 'blockquote') {
            segments.add('"$text"');
          } else {
            segments.add(text);
          }
        }
        return;
        
      case 'table':
        // Xử lý bảng: ghép header (thẻ <th> trong <thead>) và mỗi hàng <tr> của tbody thành 1 chunk
        String headerText = "";
        Element? thead = element.querySelector('thead');
        
        // Trích xuất tiêu đề (header) của bảng từ thead
        if (thead != null) {
          List<String> headerCells = [];
          for (var th in thead.querySelectorAll('th')) {
            headerCells.add(normalizeText(th.text));
          }
          if (headerCells.isNotEmpty) {
            headerText = headerCells.join(' | ');
          }
        }
        
        // Lấy các hàng dữ liệu từ tbody hoặc tr không nằm trong thead
        List<Element> rows = [];
        Element? tbody = element.querySelector('tbody');
        
        if (tbody != null) {
          rows = tbody.querySelectorAll('tr');
        } else {
          // Lấy tất cả các <tr> nếu không có tbody
          var allRows = element.querySelectorAll('tr');
          if (thead != null) {
            rows = allRows.where((row) => row.parent != thead).toList();
          } else {
            rows = allRows;
          }
        }
        
        // Tạo nội dung bảng với mỗi hàng là một dòng
        List<String> tableRows = [];
        if (headerText.isNotEmpty) {
          tableRows.add(headerText);
          tableRows.add('-' * headerText.length); // Thêm dấu gạch ngang sau header
        }
        
        // Xử lý từng hàng dữ liệu
        for (var row in rows) {
          List<String> rowCells = [];
          for (var cell in row.querySelectorAll('td, th')) {
            rowCells.add(normalizeText(cell.text));
          }
          
          if (rowCells.isNotEmpty) {
            tableRows.add(rowCells.join(' | '));
          }
        }
        
        if (tableRows.isNotEmpty) {
          segments.add(tableRows.join('\n'));
        }
        return;
        
      case 'ul':
      case 'ol':
        // Kiểm tra xem có phải mục lục không
        if (element.parent != null && 
            normalizeText(element.parent!.text).toLowerCase().contains('mục lục')) {
          List<String> tocItems = [];
          for (var li in element.querySelectorAll('li')) {
            String cleanItem = normalizeText(li.text);
            if (cleanItem.isNotEmpty) {
              tocItems.add(cleanItem);
            }
          }
          
          String heading = '';
          var h2 = _findPreviousHeading(element, 'h2');
          if (h2 != null && normalizeText(h2.text).toLowerCase().contains('mục lục')) {
            heading = normalizeText(h2.text);
          }
          
          if (tocItems.isNotEmpty) {
            // Sử dụng xuống dòng thay vì dấu chấm phẩy để định dạng mục lục
            if (heading.isNotEmpty) {
              segments.add('$heading:\n${tocItems.join('\n')}');
            } else {
              segments.add(tocItems.join('\n'));
            }
          }
          return;
        } else {
          // Xử lý từng mục trong danh sách
          for (var li in element.querySelectorAll('li')) {
            String liText = normalizeText(li.text);
            if (liText.isEmpty) continue;
            
            // Tách thành các câu
            List<String> sentences = liText.split(RegExp(r'(?<=[.!?…])\s+'));
            sentences = sentences
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            
            if (sentences.length <= 3) {
              segments.add(sentences.join(' '));
            } else {
              // Áp dụng thuật toán group_sentences_with_long_check
              segments.addAll(groupSentencesWithLongCheck(sentences));
            }
          }
        }
        return;
        
      case 'img':
        String altText = element.attributes['alt'] ?? '';
        if (altText.isNotEmpty) {
          segments.add('[Hình ảnh: $altText]');
        } else {
          segments.add('[Hình ảnh]');
        }
        return;
        
      case 'p':
        String text = normalizeText(element.text);
        if (text.isNotEmpty) {
          // Make sure paragraphs end with proper sentence ending punctuation
          String cleanText = text;
          if (!cleanText.trim().endsWith('.') && 
              !cleanText.trim().endsWith('!') && 
              !cleanText.trim().endsWith('?') &&
              !cleanText.trim().endsWith('…') &&
              !cleanText.trim().endsWith(').') && 
              !cleanText.trim().endsWith('!)') && 
              !cleanText.trim().endsWith('?)') &&
              !cleanText.trim().endsWith('…)')) {
            // Add period if missing
            cleanText = cleanText.trim() + '.';
          }
          
          // Split into sentences while preserving quoted text
          List<String> sentences = splitTextPreservingQuotes(cleanText);
          
          // Keep the quoted text together by not splitting it further
          sentences = sentences
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          
          segments.addAll(groupSentencesWithLongCheck(sentences));
          return;
        }
        break;
    }
    
    // Xử lý đệ quy các phần tử con
    List<String> childSegments = [];
    for (var child in element.children) {
      processElement(child, childSegments, parentTag: element);
    }
    
    // Nếu element có text trực tiếp bên ngoài các thẻ con
    if (childSegments.isEmpty) {
      String directText = normalizeText(element.text);
      if (directText.isNotEmpty) {
        segments.add(directText);
      }
    } else {
      // Gộp các đoạn con ngắn nếu chúng thuộc cùng một parent
      if (parentTag != null && 
          childSegments.every((segment) => segment.length < 50)) {
        segments.add(childSegments.join(' '));
      } else {
        segments.addAll(childSegments);
      }
    }
  }
  
  /// Split text into sentences, preserving quotes and parentheses intact
  static List<String> splitTextPreservingQuotes(String text) {
    // Simple direct approach for paragraphs
    List<String> sentences = [];
    
    // First check if the paragraph already ends with a proper sentence ending
    if (text.trim().endsWith('.') || 
        text.trim().endsWith('!') || 
        text.trim().endsWith('?') ||
        text.trim().endsWith('…') ||
        text.trim().endsWith(').') ||
        text.trim().endsWith('!)') ||
        text.trim().endsWith('?)') ||
        text.trim().endsWith('…)')) {
      
      // Basic sentence splitting that respects quotes and parentheses
      int inQuote = 0;
      int inParen = 0;
      StringBuilder current = StringBuilder();
      
      for (int i = 0; i < text.length; i++) {
        current.write(text[i]);
        
        // Track quotes and parentheses
        if (text[i] == '"') inQuote = 1 - inQuote; // Toggle between 0 and 1
        if (text[i] == '(') inParen++;
        if (text[i] == ')') inParen = inParen > 0 ? inParen - 1 : 0;
        
        // Check for sentence end, but only when not in quotes or parentheses
        bool isEndPunctuation = text[i] == '.' || text[i] == '!' || text[i] == '?' || text[i] == '…';
        
        if (isEndPunctuation && inQuote == 0 && inParen == 0) {
          // Look ahead to see if this is truly the end of a sentence (followed by space + capital)
          if (i == text.length - 1 || (i + 1 < text.length && text[i+1] == ' ')) {
            String sentence = current.toString().trim();
            if (sentence.isNotEmpty) {
              sentences.add(sentence);
              current = StringBuilder();
            }
          }
        }
      }
      
      // Add any remaining text
      String remaining = current.toString().trim();
      if (remaining.isNotEmpty) {
        sentences.add(remaining);
      }
    } else {
      // If the paragraph doesn't end properly, keep it as one unit
      sentences.add(text);
    }
    
    return sentences;
  }
  
  /// Nhóm danh sách câu thành các chunk với điều kiện:
  /// - Nếu một câu có số từ >= wordThreshold thì coi nó là chunk độc lập.
  /// - Nếu câu không dài, cố gắng nhóm 2 câu lại với nhau.
  static List<String> groupSentencesWithLongCheck(List<String> sentences) {
    List<String> groups = [];
    int i = 0;
    final int n = sentences.length;
    
    while (i < n) {
      String current = sentences[i];
      // Nếu current có từ >= threshold hoặc có dấu ngoặc kép, coi nó là chunk độc lập
      bool hasQuote = current.contains('"');
      if (current.split(' ').length >= wordThreshold || hasQuote) {
        groups.add(current);
        i += 1;
      } else {
        List<String> group = [current];
        i += 1;
        // Nếu có câu tiếp theo và cũng không dài thì nhóm chung
        if (i < n && sentences[i].split(' ').length < wordThreshold && !sentences[i].contains('"')) {
          group.add(sentences[i]);
          i += 1;
        }
        groups.add(group.join(' '));
      }
    }
    
    return groups;
  }
  
  /// Tìm thẻ heading trước đó
  static Element? _findPreviousHeading(Element element, String headingTag) {
    Element? current = element.previousElementSibling;
    while (current != null) {
      if (current.localName == headingTag) {
        return current;
      }
      current = current.previousElementSibling;
    }
    return null;
  }
  
  /// Tách văn bản dài thành các đoạn nhỏ hơn
  static List<String> splitLongText(String text) {
    List<String> segments = [];
    
    // Kiểm tra xem có phải định dạng "Tiêu đề: Nội dung" không
    if (text.contains(': ')) {
      List<String> parts = text.split(RegExp(r':\s+'));
      if (parts.length > 1) {
        // Nếu phần đầu tiên có vẻ như là tiêu đề
        if (parts[0].length < 80 && 
            (parts[0].toUpperCase() == parts[0] || parts[0].length < 50)) {
          segments.add(parts[0]);
          
          // Xử lý phần còn lại
          if (parts.length > 1) {
            String remainingText = parts.sublist(1).join(': ');
            List<String> sentences = remainingText.split(RegExp(r'(?<=[.!?…])\s+'));
            sentences = sentences
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            segments.addAll(groupSentencesWithLongCheck(sentences));
          }
          return segments;
        }
      }
    }
    
    // Nếu không phải định dạng tiêu đề, tách theo câu
    List<String> sentences = text.split(RegExp(r'(?<=[.!?…])\s+'));
    sentences = sentences
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return groupSentencesWithLongCheck(sentences);
  }
  
  /// Tách văn bản thành các câu (phương thức này giữ lại để tương thích ngược)
  static List<String> splitBySentences(String text) {
    // Tách theo dấu kết thúc câu
    List<String> sentences = text.split(RegExp(r'(?<=[.!?…])\s+'));
    sentences = sentences
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    
    return groupSentencesWithLongCheck(sentences);
  }
} 