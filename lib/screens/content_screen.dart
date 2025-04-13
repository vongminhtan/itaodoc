// File: lib/screens/content_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:math' show min, max;

import '../view_models/browser_view_model.dart';
import '../models/browser_segment.dart';

/// Widget hiển thị nội dung của một segment (text hoặc image)
Widget buildSegmentView(BrowserSegment segment) {
  if (segment.type == BrowserSegmentType.text) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        segment.content,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, color: Colors.black87),
      ),
    );
  } else if (segment.type == BrowserSegmentType.image) {
    return Image.network(
      segment.content,
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 50),
            Text("Không tải được ảnh."),
          ],
        );
      },
    );
  }
  return Container();
}

/// Widget ContentScreen: màn hình chính hiển thị nội dung đọc và các điều khiển
class ContentScreen extends StatefulWidget {
  const ContentScreen({Key? key}) : super(key: key);

  @override
  _ContentScreenState createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();
  File? _backgroundImage; // Reading background
  File? _overallBackgroundImage; // Overall app background
  bool _showBackgroundOptions = false;
  
  @override
  void initState() {
    super.initState();
    _loadSavedBackgroundImage();
    _loadSavedOverallBackgroundImage();
    
    // Load saved color and opacity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<BrowserViewModel>(context, listen: false);
      viewModel.loadSavedTextColor();
      viewModel.loadSavedOpacity();
    });
  }

  // Methods for reading background image
  Future<void> _loadSavedBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('backgroundImagePath');
    if (imagePath != null) {
      final file = File(imagePath);
      if (file.existsSync()) {
        setState(() {
          _backgroundImage = file;
        });
      }
    }
  }

  // Methods for overall background image
  Future<void> _loadSavedOverallBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('overallBackgroundImagePath');
    if (imagePath != null) {
      final file = File(imagePath);
      if (file.existsSync()) {
        setState(() {
          _overallBackgroundImage = file;
        });
      }
    }
  }

  Future<void> _saveBackgroundImagePath(File? file) async {
    final prefs = await SharedPreferences.getInstance();
    if (file != null) {
      await prefs.setString('backgroundImagePath', file.path);
    } else {
      await prefs.remove('backgroundImagePath');
    }
  }

  Future<void> _saveOverallBackgroundImagePath(File? file) async {
    final prefs = await SharedPreferences.getInstance();
    if (file != null) {
      await prefs.setString('overallBackgroundImagePath', file.path);
    } else {
      await prefs.remove('overallBackgroundImagePath');
    }
  }

  Future<void> _pickBackgroundImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _backgroundImage = File(image.path);
      });
      _saveBackgroundImagePath(_backgroundImage);
    }
  }

  Future<void> _pickOverallBackgroundImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _overallBackgroundImage = File(image.path);
      });
      _saveOverallBackgroundImagePath(_overallBackgroundImage);
    }
  }

  void _clearBackgroundImage() {
    setState(() {
      _backgroundImage = null;
    });
    _saveBackgroundImagePath(null);
  }

  void _clearOverallBackgroundImage() {
    setState(() {
      _overallBackgroundImage = null;
    });
    _saveOverallBackgroundImagePath(null);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _showTextColorPicker(BrowserViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn màu chữ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Predefined colors
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildColorOption(Colors.black, viewModel),
                  _buildColorOption(Colors.white, viewModel),
                  _buildColorOption(Colors.red.shade900, viewModel),
                  _buildColorOption(Colors.blue.shade900, viewModel),
                  _buildColorOption(Colors.green.shade900, viewModel),
                  _buildColorOption(Colors.amber.shade900, viewModel),
                  _buildColorOption(Colors.purple.shade900, viewModel),
                  _buildColorOption(Colors.teal.shade900, viewModel),
                ],
              ),
              const SizedBox(height: 20),
              // Custom color picker
              ColorPicker(
                pickerColor: viewModel.textColor,
                onColorChanged: (color) {
                  viewModel.changeTextColor(color);
                },
                pickerAreaHeightPercent: 0.8,
                labelTypes: const [],
                pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
                enableAlpha: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color, BrowserViewModel viewModel) {
    return GestureDetector(
      onTap: () {
        viewModel.changeTextColor(color);
        Navigator.of(context).pop(); // Close dialog immediately when color selected
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: viewModel.textColor.value == color.value
            ? Icon(Icons.check, color: color == Colors.white ? Colors.black : Colors.white)
            : null,
      ),
    );
  }

  void _openBackgroundOptionsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Chọn ảnh nền đọc'),
              onTap: () {
                Navigator.pop(context);
                _pickBackgroundImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Xóa ảnh nền đọc'),
              onTap: () {
                Navigator.pop(context);
                _clearBackgroundImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper),
              title: const Text('Chọn ảnh nền ứng dụng'),
              onTap: () {
                Navigator.pop(context);
                _pickOverallBackgroundImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Xóa ảnh nền ứng dụng'),
              onTap: () {
                Navigator.pop(context);
                _clearOverallBackgroundImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.opacity),
              title: const Text('Điều chỉnh độ trong suốt'),
              onTap: () {
                Navigator.pop(context);
                _showOpacitySlider();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOpacitySlider() {
    final viewModel = Provider.of<BrowserViewModel>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điều chỉnh độ trong suốt'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Độ trong suốt: ${(viewModel.readingBackgroundOpacity * 100).round()}%'),
              Slider(
                value: viewModel.readingBackgroundOpacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (value) {
                  setState(() {
                    viewModel.changeReadingBackgroundOpacity(value);
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }

  // Function to copy current content to clipboard
  void _copyCurrentContent(BrowserViewModel viewModel) {
    if (viewModel.segments.isEmpty) return;
    
    final segment = viewModel.segments[viewModel.currentIndex];
    if (segment.isText) {
      Clipboard.setData(ClipboardData(text: segment.content.trim()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Văn bản đã được sao chép vào bảng tạm')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể sao chép nội dung hình ảnh')),
      );
    }
  }

  void _showJumpToPageDialog(BrowserViewModel viewModel) {
    final TextEditingController pageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhảy đến trang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pageController,
              decoration: const InputDecoration(labelText: 'Số trang'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
            const SizedBox(height: 10),
            Text('Tổng số trang: ${viewModel.segments.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final pageNumber = int.tryParse(pageController.text);
              if (pageNumber != null && pageNumber > 0 && pageNumber <= viewModel.segments.length) {
                viewModel.jumpToPage(pageNumber - 1);
                Navigator.pop(context);
              } else {
                // Show error for invalid page number
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Số trang không hợp lệ')),
                );
              }
            },
            child: const Text('Đi đến'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BrowserViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Color(0xFFDEF1FD),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                // Overall app background
                if (_overallBackgroundImage != null)
                  Positioned.fill(
                    child: Image.file(
                      _overallBackgroundImage!,
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.7),
                    ),
                  ),
                
                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Top bar with URL input and actions
                      _buildTopBar(viewModel),
                      
                      // Progress indicator for loading
                      if (viewModel.isLoading) LinearProgressIndicator(),
                      
                      // Error message if any
                      if (viewModel.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            viewModel.errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      
                      // Content area
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity != null) {
                              if (details.primaryVelocity! > 0 && viewModel.currentIndex > 0) {
                                viewModel.goBack();
                              } else if (details.primaryVelocity! < 0 && viewModel.currentIndex < viewModel.segments.length - 1) {
                                viewModel.goNext();
                              }
                            }
                          },
                          child: Column(
                            children: [
                              // Content view
                              Expanded(
                                child: _buildContentView(viewModel),
                              ),
                              
                              // Navigation controls
                              _buildNavigationControls(viewModel),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Background options overlay
                if (_showBackgroundOptions)
                  _buildBackgroundOptionsOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentBackground() {
    final viewModel = Provider.of<BrowserViewModel>(context);
    
    if (_backgroundImage != null) {
      return Opacity(
        opacity: viewModel.readingBackgroundOpacity,
        child: Image.file(
          _backgroundImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else {
      // Light yellow background that's better for reading
      return Opacity(
        opacity: viewModel.readingBackgroundOpacity,
        child: Container(
          color: Color(0xFFFFF8E1), // Subtle warm yellow color, easier on the eyes
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
  }

  Widget _buildBackgroundOptionsOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        // Close the overlay when tapping outside the content area
        onTap: () {
          setState(() {
            _showBackgroundOptions = false;
          });
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                // Prevent taps inside the content from closing the overlay
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tùy chỉnh hình nền',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Swapped positions: App background on the left, reading background on the right
                          _buildBackgroundOption(
                            icon: Icons.wallpaper,
                            label: 'Nền app',
                            onTap: _pickOverallBackgroundImage,
                            onClear: _clearOverallBackgroundImage,
                            hasImage: _overallBackgroundImage != null,
                            imageFile: _overallBackgroundImage,
                          ),
                          _buildBackgroundOption(
                            icon: Icons.image_outlined,
                            label: 'Nền đọc',
                            onTap: _pickBackgroundImage,
                            onClear: _clearBackgroundImage,
                            hasImage: _backgroundImage != null,
                            imageFile: _backgroundImage,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Consumer<BrowserViewModel>(
                        builder: (context, viewModel, child) {
                          return Column(
                            children: [
                              Text(
                                'Độ mờ nền đọc: ${(viewModel.readingBackgroundOpacity * 100).toInt()}%',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Slider(
                                value: viewModel.readingBackgroundOpacity,
                                min: 0.0,
                                max: 1.0,
                                divisions: 10,
                                onChanged: (value) {
                                  viewModel.changeReadingBackgroundOpacity(value);
                                },
                                activeColor: Colors.blue,
                                inactiveColor: Colors.blue.withOpacity(0.3),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showBackgroundOptions = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Đóng'),
                      ),
                      SizedBox(height: 10), // Extra space at bottom to account for system navigation
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required bool hasImage,
    File? imageFile,
  }) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: hasImage && imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Colors.white, size: 22),
                            onPressed: onTap,
                            padding: EdgeInsets.all(4),
                            constraints: BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : IconButton(
                  icon: Icon(icon, size: 40, color: Colors.white),
                  onPressed: onTap,
                ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white)),
        if (hasImage)
          TextButton.icon(
            onPressed: onClear,
            icon: Icon(Icons.delete, size: 16, color: Colors.red.shade300),
            label: Text('Xóa', style: TextStyle(color: Colors.red.shade300)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar(BrowserViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Row 1: URL input and paste button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      
                      // URL input field
                      Expanded(
                        child: TextField(
                          focusNode: _urlFocusNode,
                          controller: _urlController..text = viewModel.urlInputText,
                          onChanged: (value) => viewModel.urlInputText = value,
                          onSubmitted: (_) {
                            _urlFocusNode.unfocus();
                            viewModel.loadURL();
                          },
                          decoration: InputDecoration(
                            hintText: 'Nhập địa chỉ trang web',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      
                      // Search button
                      IconButton(
                        icon: const Icon(Icons.search, size: 20),
                        tooltip: 'Tải URL',
                        onPressed: () {
                          _urlFocusNode.unfocus();
                          viewModel.loadURL();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Paste button (with white background like toolbar)
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildActionButton(
                  icon: Icons.content_paste,
                  tooltip: 'Dán và Dứt',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null && data.text != null) {
                      _urlController.text = data.text!;
                      viewModel.urlInputText = data.text!;
                      // Load the URL immediately after pasting
                      viewModel.loadURL();
                    }
                  },
                ),
              ),
            ],
          ),
          
          // Row 2: Toolbar with all action buttons
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left side buttons
                Row(
                  children: [
                    // Copy button (only shown when there's content)
                    if (viewModel.segments.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildActionButton(
                          icon: Icons.copy,
                          tooltip: 'Sao chép',
                          onPressed: () => _copyCurrentContent(viewModel),
                        ),
                      ),
                  ],
                ),
                
                SizedBox(width: 16), // Add some space between left and right buttons
                
                // Right side buttons in a single container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.refresh,
                        tooltip: 'Làm mới',
                        onPressed: viewModel.refresh,
                      ),
                      _buildActionButton(
                        icon: Icons.history,
                        tooltip: 'Lịch sử',
                        onPressed: () => _showHistoryDialog(viewModel),
                      ),
                      _buildActionButton(
                        icon: Icons.image,
                        tooltip: 'Hình nền',
                        onPressed: () => setState(() => _showBackgroundOptions = true),
                      ),
                      _buildActionButton(
                        icon: Icons.format_color_text,
                        tooltip: 'Màu chữ',
                        onPressed: () => _showTextColorPicker(viewModel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required VoidCallback onPressed, 
    String? tooltip
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.blue.shade700),
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 22,
      padding: EdgeInsets.all(8),
      constraints: BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  Widget _buildContentView(BrowserViewModel viewModel) {
    if (viewModel.segments.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Nhớ yêu lấy sự học nha mấy má!',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      final segment = viewModel.segments[viewModel.currentIndex];
      final maxHeight = min(MediaQuery.of(context).size.height * 0.6, 500.0);
      final contentWidth = max(150.0, MediaQuery.of(context).size.width * 0.9);
      
      return Center(
        child: SizedBox(
          width: contentWidth, // Fixed width as requested
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            child: IntrinsicHeight(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Positioned.fill(child: _buildContentBackground()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: segment.isText
                          ? GestureDetector(
                              onLongPress: () {
                                _copyCurrentContent(viewModel);
                              },
                              child: SingleChildScrollView(
                                child: Text(
                                  segment.content.trim(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: viewModel.textColor,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: segment.content,
                              placeholder: (context, url) => 
                                  const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => 
                                  const Icon(Icons.error, size: 64),
                              fit: BoxFit.contain,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildNavigationControls(BrowserViewModel viewModel) {
    if (viewModel.segments.isEmpty) return SizedBox.shrink();
    
    return Column(
      children: [
        // Page indicator
        GestureDetector(
          onTap: () => _showJumpToPageDialog(viewModel),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFFCE6C8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${viewModel.currentIndex + 1} / ${viewModel.segments.length} 📄",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        
        // Navigation buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: viewModel.currentIndex > 0 ? viewModel.goBack : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black54,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Icon(Icons.arrow_back_ios, size: 22),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: viewModel.currentIndex < viewModel.segments.length - 1 ? viewModel.goNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black54,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Icon(Icons.arrow_forward_ios, size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Show history dialog with alternating row colors
  void _showHistoryDialog(BrowserViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lịch sử duyệt web'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: viewModel.browserHistory.length,
            itemBuilder: (context, index) {
              final item = viewModel.browserHistory[viewModel.browserHistory.length - 1 - index];
              return Container(
                color: index % 2 == 0 ? Colors.blue.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                child: ListTile(
                  title: Text(
                    item['title'] ?? 'Không có tiêu đề',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item['url'] ?? '',
                    style: TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    viewModel.urlInputText = item['url'] ?? '';
                    viewModel.loadURL();
                  },
                  leading: Icon(Icons.history, color: Colors.blue.shade300, size: 20),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
