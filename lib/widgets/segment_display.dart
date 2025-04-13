// File: lib/widgets/segment_display.dart

import 'package:flutter/material.dart';
import '../models/browser_segment.dart';

class SegmentDisplay extends StatelessWidget {
  final BrowserSegment segment;

  const SegmentDisplay({Key? key, required this.segment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (segment.type) {
      case BrowserSegmentType.text:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            segment.content,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, height: 1.5),
          ),
        );
      case BrowserSegmentType.image:
        return Image.network(
          segment.content,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.broken_image, size: 50),
                SizedBox(height: 8),
                Text("Không tải được ảnh."),
              ],
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
    }
  }
}
