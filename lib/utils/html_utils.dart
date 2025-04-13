import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';

/// Utility class for HTML parsing
class HtmlUtils {
  /// Extract the title from an HTML document
  static String extractTitle(String htmlContent) {
    var document = html.parse(htmlContent);
    var titleElement = document.querySelector('title');
    return titleElement?.text.trim() ?? '';
  }

  /// Extract all image URLs from an HTML document
  static List<String> extractImages(String htmlContent, Uri baseUri) {
    var document = html.parse(htmlContent);
    var imageElements = document.querySelectorAll('img');
    List<String> imageUrls = [];

    for (Element img in imageElements) {
      String? src = img.attributes['src'];
      if (src != null && src.isNotEmpty) {
        // Handle relative URLs
        if (src.startsWith('/')) {
          src = "${baseUri.scheme}://${baseUri.host}$src";
        } else if (!src.startsWith('http')) {
          String base = baseUri.toString();
          if (base.endsWith('/')) {
            src = "$base$src";
          } else {
            src = "$base/$src";
          }
        }
        imageUrls.add(src);
      }
    }

    return imageUrls;
  }

  /// Clean up HTML content by removing scripts, styles, etc.
  static String cleanHtml(String htmlContent) {
    var document = html.parse(htmlContent);
    
    // Remove scripts and styles
    document.querySelectorAll('script').forEach((element) => element.remove());
    document.querySelectorAll('style').forEach((element) => element.remove());
    
    // Return the text content
    return document.body?.text.trim() ?? '';
  }
  
  /// Extract text content with structure preservation
  static List<String> extractStructuredText(String htmlContent) {
    var document = html.parse(htmlContent);
    List<String> segments = [];
    
    // Remove scripts and styles
    document.querySelectorAll('script').forEach((element) => element.remove());
    document.querySelectorAll('style').forEach((element) => element.remove());
    
    // Process the body
    if (document.body != null) {
      _processNode(document.body!, segments);
    }
    
    // Clean up the segments
    segments = segments.map((segment) => _cleanText(segment)).where((segment) => segment.isNotEmpty).toList();
    
    return segments;
  }
  
  /// Process a node recursively to extract structured text
  static void _processNode(Element node, List<String> segments) {
    // Handle headings first
    if (node.localName != null && node.localName!.startsWith('h') && node.localName!.length == 2) {
      String heading = node.text.trim();
      if (heading.isNotEmpty) {
        segments.add(heading);
      }
      return;
    }
    
    // Process special elements
    switch (node.localName) {
      case 'p':
      case 'div':
      case 'section':
      case 'article':
        String text = node.text.trim();
        if (text.isNotEmpty) {
          // Check if the paragraph is long and contains multiple sentences
          if (text.length > 200 && _hasMultipleSentences(text)) {
            segments.addAll(_splitLongText(text));
          } else {
            segments.add(text);
          }
        }
        break;
      
      case 'ul':
      case 'ol':
        node.querySelectorAll('li').forEach((li) {
          String item = li.text.trim();
          if (item.isNotEmpty) {
            segments.add(item);
          }
        });
        break;
      
      case 'table':
        // For tables, process each row separately
        node.querySelectorAll('tr').forEach((tr) {
          String rowText = tr.text.trim();
          if (rowText.isNotEmpty) {
            segments.add(rowText);
          }
        });
        break;
      
      default:
        // Recursively process child nodes
        for (var child in node.nodes) {
          if (child is Element) {
            _processNode(child, segments);
          }
        }
    }
  }
  
  /// Clean up text by removing extra whitespace and normalizing
  static String _cleanText(String text) {
    // Replace multiple spaces/newlines with a single space
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  
  /// Check if text has multiple sentences
  static bool _hasMultipleSentences(String text) {
    return RegExp(r'[.!?]\s+[A-Z]').hasMatch(text);
  }
  
  /// Split long text into smaller, more readable chunks
  static List<String> _splitLongText(String text) {
    List<String> segments = [];
    
    // First try to split by common section indicators
    if (text.contains(': ')) {
      var parts = text.split(RegExp(r':\s+'));
      if (parts.length > 1) {
        // If we find colons, check if the first part looks like a title/header
        if (parts[0].length < 80 && parts[0].toUpperCase() == parts[0] ||
            parts[0].length < 50) {
          segments.add(parts[0]);
          // Handle the rest of the content
          if (parts.length > 1) {
            // Join the rest and then try to split by sentences
            String remainingText = parts.sublist(1).join(': ');
            segments.addAll(_splitBySentences(remainingText));
          }
          return segments;
        }
      }
    }
    
    // If we couldn't split by sections, split by sentences
    return _splitBySentences(text);
  }
  
  /// Split text by sentences
  static List<String> _splitBySentences(String text) {
    List<String> sentences = [];
    RegExp sentencePattern = RegExp(r'(?<=[.!?])\s+');
    
    // Split by sentence terminators
    sentences = text.split(sentencePattern);
    
    // Combine very short sentences with the next one
    List<String> combined = [];
    String buffer = '';
    
    for (String sentence in sentences) {
      if (buffer.isEmpty) {
        buffer = sentence;
      } else if (buffer.length < 30) {
        buffer += ' ' + sentence;
      } else {
        combined.add(buffer);
        buffer = sentence;
      }
    }
    
    if (buffer.isNotEmpty) {
      combined.add(buffer);
    }
    
    return combined;
  }
} 