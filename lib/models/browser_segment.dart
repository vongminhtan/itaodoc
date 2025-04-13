// File: lib/models/browser_segment.dart

/// Represents a segment of content that can be either text or an image.
enum BrowserSegmentType { text, image }

class BrowserSegment {
  final BrowserSegmentType type;
  final String content; // Either text content or image URL

  BrowserSegment.text(String text) 
      : type = BrowserSegmentType.text, 
        content = text;

  BrowserSegment.image(String imageUrl) 
      : type = BrowserSegmentType.image, 
        content = imageUrl;

  bool get isText => type == BrowserSegmentType.text;
  bool get isImage => type == BrowserSegmentType.image;
}
