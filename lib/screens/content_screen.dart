// File: lib/screens/content_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:math' show min, max;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pdfrx/pdfrx.dart';

import '../view_models/browser_view_model.dart';
import '../models/browser_segment.dart';

// AI service enum
enum AIService {
  gemini,
  perplexity,
}

// Proficiency levels for English learning
enum ProficiencyLevel {
  minhDe,
  lyDuc,
  taleb,
  thayBa,
}

// History tab enum
enum HistoryTab {
  links,
  pdfs,
}

// Extension method to check if a string contains English
extension StringExtension on String {
  bool containsEnglish() {
    final RegExp englishPattern = RegExp(r'[a-zA-Z]');
    return englishPattern.hasMatch(this);
  }
}

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
  
  // New variables for AI features
  String _geminiApiKey = '';
  String _perplexityApiKey = '';
  String _elevenLabsApiKey = '';
  bool _autoAI = false;
  bool _showPhonetics = false;
  String _context = '';
  ProficiencyLevel _proficiencyLevel = ProficiencyLevel.minhDe;
  AIService _selectedAIService = AIService.gemini;
  double _fontSize = 16.0;
  bool _isPlayingAudio = false;
  
  // English learning results storage
  Map<int, String> _englishLearningResults = {};
  Map<int, bool> _isLoadingEnglishLearning = {};
  
  // PDF related variables
  Map<String, String> _storedPDFs = {};
  
  // History tab selection
  HistoryTab _selectedHistoryTab = HistoryTab.links;
  bool _showHistory = false;
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  void initState() {
    super.initState();
    _loadSavedBackgroundImage();
    _loadSavedOverallBackgroundImage();
    _loadSettings();
    _loadStoredPDFs();
    
    // Load saved color and opacity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<BrowserViewModel>(context, listen: false);
      viewModel.loadSavedTextColor();
      viewModel.loadSavedOpacity();
    });
  }
  
  // Load saved settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _geminiApiKey = prefs.getString('geminiAPIKey') ?? '';
      _perplexityApiKey = prefs.getString('perplexityAPIKey') ?? '';
      _elevenLabsApiKey = prefs.getString('elevenLabsAPIKey') ?? '';
      _autoAI = prefs.getBool('autoAI') ?? false;
      _showPhonetics = prefs.getBool('showPhonetics') ?? false;
      _context = prefs.getString('learningContext') ?? '';
      _fontSize = prefs.getDouble('fontSizeValue') ?? 16.0;
      
      final savedLevel = prefs.getString('proficiencyLevel');
      if (savedLevel != null) {
        _proficiencyLevel = ProficiencyLevel.values.firstWhere(
          (level) => level.toString() == savedLevel,
          orElse: () => ProficiencyLevel.minhDe
        );
      }
      
      final savedService = prefs.getString('selectedAIService');
      if (savedService != null) {
        _selectedAIService = AIService.values.firstWhere(
          (service) => service.toString() == savedService,
          orElse: () => AIService.gemini
        );
      }
    });
  }
  
  // Load stored PDFs
  Future<void> _loadStoredPDFs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPDFsJson = prefs.getString('storedPDFs');
    if (storedPDFsJson != null) {
      setState(() {
        _storedPDFs = Map<String, String>.from(json.decode(storedPDFsJson));
      });
    }
  }
  
  // Save stored PDFs
  Future<void> _saveStoredPDFs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storedPDFs', json.encode(_storedPDFs));
  }
  
  // Save settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiAPIKey', _geminiApiKey);
    await prefs.setString('perplexityAPIKey', _perplexityApiKey);
    await prefs.setString('elevenLabsAPIKey', _elevenLabsApiKey);
    await prefs.setBool('autoAI', _autoAI);
    await prefs.setBool('showPhonetics', _showPhonetics);
    await prefs.setString('learningContext', _context);
    await prefs.setString('proficiencyLevel', _proficiencyLevel.toString());
    await prefs.setString('selectedAIService', _selectedAIService.toString());
    await prefs.setDouble('fontSizeValue', _fontSize);
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
    _audioPlayer.dispose();
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
                      
                      // History panel if shown
                      if (_showHistory)
                        _buildHistoryPanel(viewModel),
                        
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
                  
                // Audio player indicator
                if (_isPlayingAudio)
                  _buildAudioPlayerIndicator(),
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
                        onPressed: () => setState(() => _showHistory = !_showHistory),
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
                      _buildActionButton(
                        icon: Icons.picture_as_pdf,
                        tooltip: 'Tải PDF',
                        onPressed: _pickPDF,
                      ),
                      _buildActionButton(
                        icon: Icons.settings,
                        tooltip: 'Cài đặt AI',
                        onPressed: _showSettings,
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
      
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              // Original content (text or image)
              Container(
                width: double.infinity,
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
                  children: [
                    Positioned.fill(child: _buildContentBackground()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: segment.isText
                          ? GestureDetector(
                              onLongPress: () {
                                _copyCurrentContent(viewModel);
                              },
                              child: Text(
                                segment.content.trim(),
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  color: viewModel.textColor,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.left,
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
              
              // English learning section (only for text segments with English)
              if (segment.isText && segment.content.containsEnglish())
                _buildAIResultWidget(viewModel.currentIndex),
            ],
          ),
        ),
      );
    }
  }
  
  // Build AI result widget
  Widget _buildAIResultWidget(int index) {
    if (_isLoadingEnglishLearning[index] == true) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 10, bottom: 10),
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Úm ba la ây ai cúc cúc',
                style: TextStyle(
                  fontSize: _fontSize - 2,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_englishLearningResults.containsKey(index)) {
      final result = _englishLearningResults[index]!;
      
      // Check if it's an error message
      if (result.startsWith('⚠️ Lỗi AI:')) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 10, bottom: 10),
          padding: EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  result,
                  style: TextStyle(
                    fontSize: _fontSize - 2,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.withOpacity(0.9),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade900,
                  ),
                  child: Text('Đi đến Cài đặt API'),
                ),
              ),
            ],
          ),
        );
      }
      
      // Regular content
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 10, bottom: 10),
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Học tiếng Anh',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Divider(color: Colors.blue.shade100),
                  Text(
                    result,
                    style: TextStyle(
                      fontSize: _fontSize - 2,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // TTS button
            if (_elevenLabsApiKey.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(right: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isPlayingAudio ? _stopAudio : () => _readText(result),
                    icon: Icon(_isPlayingAudio ? Icons.stop : Icons.volume_up),
                    label: Text(_isPlayingAudio ? 'Dừng' : 'Nghe'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (!_autoAI) {
      return Container(
        margin: EdgeInsets.only(top: 10, bottom: 10),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton.icon(
          onPressed: () => _requestEnglishLearning(index),
          icon: Icon(Icons.psychology),
          label: Text('Học tiếng Anh'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue.shade700,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
    
    return SizedBox();
  }
  
  // Build audio player indicator
  Widget _buildAudioPlayerIndicator() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(width: 15),
              Text(
                'Đang phát audio...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(width: 15),
              InkWell(
                onTap: _stopAudio,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.stop,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // Show history panel
  Widget _buildHistoryPanel(BrowserViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lịch sử duyệt',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Spacer(),
              // Tab selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildHistoryTab(HistoryTab.links),
                    _buildHistoryTab(HistoryTab.pdfs),
                  ],
                ),
              ),
              SizedBox(width: 8),
              // Close button
              IconButton(
                icon: Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _showHistory = false),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: EdgeInsets.all(4),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 200,
            child: _filteredHistory(viewModel).isEmpty
                ? Center(
                    child: Text(
                      'Không có lịch sử',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredHistory(viewModel).length,
                    itemBuilder: (context, index) {
                      final item = _filteredHistory(viewModel)[index];
                      final entry = item['url'] ?? '';
                      final title = item['title'] ?? 'Không có tiêu đề';
                      
                      return Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              entry.startsWith('PDF:')
                                  ? Icons.picture_as_pdf
                                  : Icons.language,
                              color: Colors.grey,
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                color: entry == viewModel.currentURL
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red, size: 18),
                              onPressed: () => _deleteHistoryEntry(viewModel, entry),
                            ),
                            onTap: () {
                              _handleHistoryNavigation(viewModel, entry);
                              setState(() {
                                _showHistory = false;
                              });
                            },
                          ),
                          Divider(height: 1, indent: 56),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  // Build tab for history view
  Widget _buildHistoryTab(HistoryTab tab) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHistoryTab = tab;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: _selectedHistoryTab == tab
              ? Colors.blue.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tab == HistoryTab.links ? 'Web' : 'PDF',
          style: TextStyle(
            color: _selectedHistoryTab == tab ? Colors.blue : Colors.black,
            fontSize: 12,
            fontWeight: _selectedHistoryTab == tab ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  // Filter history based on selected tab
  List<Map<String, String>> _filteredHistory(BrowserViewModel viewModel) {
    return viewModel.browserHistory.where((item) {
      final url = item['url'] ?? '';
      switch (_selectedHistoryTab) {
        case HistoryTab.links:
          return !url.startsWith('PDF:');
        case HistoryTab.pdfs:
          return url.startsWith('PDF:');
      }
    }).toList();
  }
  
  // Delete history entry
  void _deleteHistoryEntry(BrowserViewModel viewModel, String entry) {
    if (entry.startsWith('PDF:')) {
      _deletePDFFromHistory(entry);
    }
    
    setState(() {
      viewModel.browserHistory.removeWhere((item) => item['url'] == entry);
      viewModel.notifyListeners();
    });
  }
  
  // Delete PDF from history
  void _deletePDFFromHistory(String entry) {
    if (entry.startsWith('PDF:')) {
      final pdfPath = _storedPDFs[entry];
      if (pdfPath != null) {
        final file = File(pdfPath);
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          print("Error deleting PDF file: $e");
        }
        _storedPDFs.remove(entry);
        _saveStoredPDFs();
      }
    }
  }
  
  // Handle history navigation
  void _handleHistoryNavigation(BrowserViewModel viewModel, String entry) {
    // If the entry is a PDF
    if (entry.startsWith('PDF:')) {
      final pdfPath = _storedPDFs[entry];
      if (pdfPath != null) {
        final file = File(pdfPath);
        if (file.existsSync()) {
          // Clear resources before loading a new PDF
          viewModel.segments = [];
          viewModel.currentIndex = 0;
          viewModel.notifyListeners();
          
          // Load the PDF
          _loadPDF(file);
        } else {
          setState(() {
            viewModel.errorMessage = "Không thể tìm thấy file PDF. Hãy chọn lại file từ nút 'Tải PDF'.";
          });
          _storedPDFs.remove(entry);
          _saveStoredPDFs();
        }
      } else {
        setState(() {
          viewModel.errorMessage = "Không thể tìm thấy file PDF. Hãy chọn lại file từ nút 'Tải PDF'.";
        });
      }
    } else {
      // For normal web URLs, clear any segments first
      viewModel.segments = [];
      viewModel.currentIndex = 0;
      viewModel.urlInputText = entry;
      _urlController.text = entry;
      viewModel.loadURL();
    }
  }

  // PDF handling methods
  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _loadPDF(file);
      }
    } catch (e) {
      setState(() {
        final viewModel = Provider.of<BrowserViewModel>(context, listen: false);
        viewModel.errorMessage = "Lỗi chọn PDF: $e";
      });
    }
  }
  
  // Load PDF
  Future<void> _loadPDF(File file) async {
    final viewModel = Provider.of<BrowserViewModel>(context, listen: false);
    
    // Reset state and show loading
    viewModel.isLoading = true;
    viewModel.errorMessage = null;
    viewModel.segments = []; // Clear existing segments
    viewModel.notifyListeners();
    
    // Display name for the PDF
    final pdfDisplayName = "PDF: ${file.path.split('/').last}";
    viewModel.currentURL = pdfDisplayName;
    viewModel.urlInputText = pdfDisplayName;
    
    try {
      // Store PDF if needed
      final storedFile = await _storePDF(file);
      if (storedFile != null) {
        // Store mapping and add to history
        _storedPDFs[pdfDisplayName] = storedFile.path;
        _saveStoredPDFs();
        _updateHistory(pdfDisplayName);
        
        // Parse PDF content with image rendering
        await _parsePDFContent(storedFile, viewModel);
      } else {
        viewModel.errorMessage = "Không thể lưu file PDF.";
        viewModel.isLoading = false;
        viewModel.notifyListeners();
      }
    } catch (e) {
      viewModel.errorMessage = "Lỗi đọc PDF: $e";
      viewModel.isLoading = false;
    viewModel.notifyListeners();
    }
  }
  
  // Parse PDF content with image rendering
  Future<void> _parsePDFContent(File file, BrowserViewModel viewModel) async {
    try {
      // Open the PDF document
      final doc = await PdfDocument.openFile(file.path);
      
      List<BrowserSegment> segments = [];
      
      // Add a text segment with the PDF file name and page count
      segments.add(BrowserSegment.text("${file.path.split('/').last} (${doc.pages.length} trang)"));
      
      // Add a text segment for each page to show basic info
      // In a full implementation, you would render each page as an image
      // Unfortunately, generating images directly here would use too much memory
      // and might crash the app with larger PDF files
      for (int i = 0; i < doc.pages.length; i++) {
        final pageNum = i + 1;
        final page = doc.pages[i];
        segments.add(BrowserSegment.text(
          "Trang $pageNum - Kích thước: ${page.width.round()}x${page.height.round()} pt\n\n"
          "Nội dung PDF được hiển thị dưới dạng văn bản để tránh sử dụng quá nhiều bộ nhớ.\n"
          "Trong ứng dụng thực tế, bạn có thể sử dụng PdfViewer để hiển thị từng trang."
        ));
      }
      
      // The close method is not available in the current pdfrx version
      // await doc.close();
      
      viewModel.segments = segments;
      viewModel.currentIndex = 0;
      viewModel.isLoading = false;
      viewModel.notifyListeners();
      
      // Check for auto AI
      if (_autoAI && segments.isNotEmpty) {
        _checkAndTriggerAutoAIForCurrentSegment(viewModel);
      }
    } catch (e) {
      viewModel.isLoading = false;
      viewModel.errorMessage = "Không trích xuất được chữ từ PDF này: $e";
      viewModel.notifyListeners();
    }
  }
  
  // Store PDF file
  Future<File?> _storePDF(File sourceFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = sourceFile.path.split('/').last.replaceAll(' ', '_').replaceAll(':', '_');
      final destPath = '${appDir.path}/$fileName';
      
      // Check if file already exists
      final destFile = File(destPath);
      if (await destFile.exists()) {
        return destFile;  // Return existing file
      }
      
      // Copy file to documents directory
      return await sourceFile.copy(destPath);
    } catch (e) {
      print("Error storing PDF: $e");
      return null;
    }
  }
  
  // Update history with PDF or URL
  void _updateHistory(String entry) {
    final viewModel = Provider.of<BrowserViewModel>(context, listen: false);
    
    // Skip Google search URLs
    if (entry.contains("google.com/search?q=")) return;
    
    // Create history entry
    Map<String, String> historyEntry = {
      'url': entry,
      'title': entry.startsWith('PDF:') ? entry.replaceAll('PDF: ', '') : entry
    };
    
    // Remove current entry if it exists (avoid duplicates)
    viewModel.browserHistory.removeWhere((item) => item['url'] == entry);
    
    // Add entry at the beginning
    viewModel.browserHistory.insert(0, historyEntry);
    
    // Limit history size
    if (viewModel.browserHistory.length > 50) {
      viewModel.browserHistory.removeLast();
    }
    
    // Trigger save
    viewModel.notifyListeners();
  }
  
  // AI Learning methods
  
  // Check and trigger AI for current segment
  void _checkAndTriggerAutoAIForCurrentSegment(BrowserViewModel viewModel) {
    if (!_autoAI) return;
    
    if (viewModel.currentIndex >= 0 && viewModel.currentIndex < viewModel.segments.length) {
      final segment = viewModel.segments[viewModel.currentIndex];
      if (segment.isText && segment.content.containsEnglish() && 
          !_englishLearningResults.containsKey(viewModel.currentIndex) && 
          !(_isLoadingEnglishLearning[viewModel.currentIndex] ?? false)) {
        _requestEnglishLearning(viewModel.currentIndex);
      }
    }
  }
  
  // Request English learning for a segment
  Future<void> _requestEnglishLearning(int segmentIndex) async {
    final viewModel = Provider.of<BrowserViewModel>(context, listen: false);
    
    if (segmentIndex < 0 || segmentIndex >= viewModel.segments.length) return;
    
    final segment = viewModel.segments[segmentIndex];
    if (!segment.isText || !segment.content.containsEnglish()) {
      return;
    }
    
    setState(() {
      _isLoadingEnglishLearning[segmentIndex] = true;
      _englishLearningResults.remove(segmentIndex);
    });
    
    final apiKey = _selectedAIService == AIService.gemini ? 
                   _geminiApiKey : _perplexityApiKey;
    
    final serviceName = _selectedAIService == AIService.gemini ? 
                        'Gemini' : 'Perplexity';
    
    if (apiKey.isEmpty) {
      setState(() {
        _englishLearningResults[segmentIndex] = "⚠️ Lỗi AI: Vui lòng nhập $serviceName API Key trong Cài đặt.";
        _isLoadingEnglishLearning[segmentIndex] = false;
      });
      return;
    }
    
    try {
      String result;
      
      if (_selectedAIService == AIService.gemini) {
        result = await _getGeminiEnglishLearningContent(
          segment.content, 
          _context, 
          _proficiencyLevel, 
          _showPhonetics
        );
      } else {
        result = await _getPerplexityEnglishLearningContent(
          segment.content, 
          _context, 
          _proficiencyLevel, 
          _showPhonetics
        );
      }
      
      setState(() {
        if (result.isEmpty) {
          _englishLearningResults[segmentIndex] = "⚠️ Lỗi AI: AI trả về nội dung trống.";
        } else if (result.length > 10000) {
          _englishLearningResults[segmentIndex] = result.substring(0, 10000) + "...";
        } else {
          _englishLearningResults[segmentIndex] = result;
        }
        _isLoadingEnglishLearning[segmentIndex] = false;
      });
    } catch (e) {
      setState(() {
        _englishLearningResults[segmentIndex] = "⚠️ Lỗi AI: ${_simplifyError(e)}";
        _isLoadingEnglishLearning[segmentIndex] = false;
      });
      print("Error fetching English learning content: $e");
    }
  }
  
  // Get English learning content from Gemini
  Future<String> _getGeminiEnglishLearningContent(
    String text, 
    String context, 
    ProficiencyLevel level,
    bool showPhonetics
  ) async {
    // Implement the real API call here
    // This is a placeholder implementation
    await Future.delayed(Duration(seconds: 2));
    
    // Return a simulated response based on the text
    if (text.toLowerCase().contains('hello') || text.toLowerCase().contains('hi')) {
      return 'Hello (/həˈloʊ/ - xin chào) everyone! How are you (bạn khoẻ không) today?';
    } else if (text.contains('work')) {
      return 'I need to work (/wɜrk/ - làm việc) hard to succeed (thành công) in my career (sự nghiệp).';
    } else {
      return 'This is (đây là) an example (ví dụ) of English learning content.';
    }
  }
  
  // Get English learning content from Perplexity
  Future<String> _getPerplexityEnglishLearningContent(
    String text, 
    String context, 
    ProficiencyLevel level,
    bool showPhonetics
  ) async {
    // Implement the real API call here
    // This is a placeholder implementation
    await Future.delayed(Duration(seconds: 2));
    
    // Return a simulated response based on the text
    if (text.toLowerCase().contains('hello') || text.toLowerCase().contains('hi')) {
      return 'Hello (/həˈloʊ/ - xin chào) everyone! How are you (bạn khoẻ không) today?';
    } else if (text.contains('work')) {
      return 'I need to work (/wɜrk/ - làm việc) hard to succeed (thành công) in my career (sự nghiệp).';
    } else {
      return 'This is (đây là) an example (ví dụ) of English learning content.';
    }
  }
  
  // Text-to-speech function
  Future<void> _readText(String text) async {
    if (_elevenLabsApiKey.isEmpty) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Chưa có API key ElevenLabs. Hãy nhập trong phần cài đặt."))
        );
      });
      return;
    }
    
    setState(() {
      _isPlayingAudio = true;
    });
    
    try {
      // In a real implementation, you would call the ElevenLabs API
      // Here we'll simulate with a delayed response
      await Future.delayed(Duration(seconds: 3));
      
      // Simulate playing audio
      // In a real implementation, you would use AudioPlayer to play the returned audio
      await Future.delayed(Duration(seconds: 3));
      
      setState(() {
        _isPlayingAudio = false;
      });
    } catch (e) {
      setState(() {
        _isPlayingAudio = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi đọc: $e"))
        );
      });
    }
  }
  
  // Stop audio playback
  void _stopAudio() {
    _audioPlayer.stop();
    setState(() {
      _isPlayingAudio = false;
    });
  }
  
  // Simplify error messages
  String _simplifyError(dynamic error) {
    String errorStr = error.toString();
    
    if (errorStr.contains("API Key is missing")) return "Chưa nhập API Key.";
    if (errorStr.contains("API key not valid")) return "API Key không hợp lệ.";
    if (errorStr.contains("429")) return "Quá nhiều yêu cầu, thử lại sau.";
    if (errorStr.contains("500") || errorStr.contains("503")) return "Lỗi máy chủ API.";
    if (errorStr.contains("SocketException")) return "Lỗi kết nối mạng.";
    
    return "Đã xảy ra lỗi không mong muốn.";
  }

  // Show settings dialog
  void _showSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cài đặt AI'),
          content: SettingsDialog(
            geminiApiKey: _geminiApiKey,
            perplexityApiKey: _perplexityApiKey,
            elevenLabsApiKey: _elevenLabsApiKey,
            selectedAIService: _selectedAIService,
            autoAI: _autoAI,
            showPhonetics: _showPhonetics,
            context: _context,
            proficiencyLevel: _proficiencyLevel,
            onSettingsChanged: (
              geminiKey,
              perplexityKey,
              elevenLabsKey,
              service,
              auto,
              phonetics,
              ctx,
              level,
            ) {
              setState(() {
                _geminiApiKey = geminiKey;
                _perplexityApiKey = perplexityKey;
                _elevenLabsApiKey = elevenLabsKey;
                _selectedAIService = service;
                _autoAI = auto;
                _showPhonetics = phonetics;
                _context = ctx;
                _proficiencyLevel = level;
              });
              _saveSettings();
              
              if (_autoAI) {
                final viewModel = Provider.of<BrowserViewModel>(context, listen: false);
                _checkAndTriggerAutoAIForCurrentSegment(viewModel);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
  
  // Show font size dialog
  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cỡ chữ'),
          content: Container(
            width: 200,
            height: 300,
            child: ListView(
              children: [
                for (double size in [12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0])
                  ListTile(
                    title: Text(
                      'Cỡ ${size.toInt()}',
                      style: TextStyle(fontSize: size),
                    ),
                    trailing: _fontSize == size ? Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () {
                      setState(() {
                        _fontSize = size;
                      });
                      _saveSettings();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Settings dialog
class SettingsDialog extends StatefulWidget {
  final String geminiApiKey;
  final String perplexityApiKey;
  final String elevenLabsApiKey;
  final AIService selectedAIService;
  final bool autoAI;
  final bool showPhonetics;
  final String context;
  final ProficiencyLevel proficiencyLevel;
  final Function(
    String geminiKey,
    String perplexityKey,
    String elevenLabsKey,
    AIService service,
    bool auto,
    bool phonetics,
    String ctx,
    ProficiencyLevel level,
  ) onSettingsChanged;
  
  SettingsDialog({
    required this.geminiApiKey,
    required this.perplexityApiKey,
    required this.elevenLabsApiKey,
    required this.selectedAIService,
    required this.autoAI,
    required this.showPhonetics,
    required this.context,
    required this.proficiencyLevel,
    required this.onSettingsChanged,
  });
  
  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _geminiApiController;
  late TextEditingController _perplexityApiController;
  late TextEditingController _elevenLabsApiController;
  late TextEditingController _contextController;
  late AIService _selectedAIService;
  late bool _autoAI;
  late bool _showPhonetics;
  late ProficiencyLevel _proficiencyLevel;
  
  @override
  void initState() {
    super.initState();
    _geminiApiController = TextEditingController(text: widget.geminiApiKey);
    _perplexityApiController = TextEditingController(text: widget.perplexityApiKey);
    _elevenLabsApiController = TextEditingController(text: widget.elevenLabsApiKey);
    _contextController = TextEditingController(text: widget.context);
    _selectedAIService = widget.selectedAIService;
    _autoAI = widget.autoAI;
    _showPhonetics = widget.showPhonetics;
    _proficiencyLevel = widget.proficiencyLevel;
  }
  
  @override
  void dispose() {
    _geminiApiController.dispose();
    _perplexityApiController.dispose();
    _elevenLabsApiController.dispose();
    _contextController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Service selection
          Text('Chọn dịch vụ AI'),
          SizedBox(height: 8),
          SegmentedButton<AIService>(
            segments: [
              ButtonSegment(
                value: AIService.gemini,
                label: Text('Gemini'),
              ),
              ButtonSegment(
                value: AIService.perplexity,
                label: Text('Perplexity'),
              ),
            ],
            selected: {_selectedAIService},
            onSelectionChanged: (Set<AIService> selection) {
              setState(() {
                _selectedAIService = selection.first;
              });
              _saveSettings();
            },
          ),
          SizedBox(height: 16),
          
          // Gemini API Key
          Text('Gemini API'),
          SizedBox(height: 8),
          TextField(
            controller: _geminiApiController,
            decoration: InputDecoration(
              hintText: 'API Key Gemini',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _saveSettings(),
          ),
          Text(
            'Sử dụng model Gemini 2.0 Flash',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 16),
          
          // Perplexity API Key
          Text('Perplexity API'),
          SizedBox(height: 8),
          TextField(
            controller: _perplexityApiController,
            decoration: InputDecoration(
              hintText: 'API Key Perplexity',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _saveSettings(),
          ),
          Text(
            'Sử dụng model sonar-pro',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 16),
          
          // ElevenLabs API Key
          Text('ElevenLabs API (Phát âm)'),
          SizedBox(height: 8),
          TextField(
            controller: _elevenLabsApiController,
            decoration: InputDecoration(
              hintText: 'API Key ElevenLabs',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _saveSettings(),
          ),
          Text(
            'Dùng để đọc từ tiếng Anh khi bạn nhấn giữ và chọn \'Đọc\'',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 16),
          
          // AI Options
          Text('Tùy chọn AI'),
          SizedBox(height: 8),
          SwitchListTile(
            title: Text('Tự động gợi ý học tiếng Anh'),
            subtitle: Text(
              'Bật: Tự động hiển thị gợi ý khi gặp nội dung tiếng Anh.\nTắt: Chỉ hiển thị nút \'Học tiếng Anh\' để bạn bấm.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _autoAI,
            onChanged: (value) {
              setState(() {
                _autoAI = value;
              });
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: Text('Có phiên âm'),
            subtitle: Text(
              'Bật: Hiển thị phiên âm tiếng Anh Mỹ trước phần dịch, ví dụ: \'worth (/wɜrθ/ - đáng giá)\'',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _showPhonetics,
            onChanged: (value) {
              setState(() {
                _showPhonetics = value;
              });
              _saveSettings();
            },
          ),
          SizedBox(height: 16),
          
          // Context
          Text('Ngữ cảnh học tập (Tùy chọn)'),
          SizedBox(height: 8),
          TextField(
            controller: _contextController,
            decoration: InputDecoration(
              hintText: 'Ngữ cảnh học tập',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => _saveSettings(),
          ),
          Text(
            'Cung cấp thêm ngữ cảnh (ví dụ: tên sách, chủ đề bài viết) để AI giải thích từ ngữ chính xác hơn.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 16),
          
          // Proficiency Level
          Text('Trình độ tiếng Anh'),
          SizedBox(height: 8),
          SegmentedButton<ProficiencyLevel>(
            segments: [
              ButtonSegment(
                value: ProficiencyLevel.minhDe,
                label: Text('Minh Dế'),
              ),
              ButtonSegment(
                value: ProficiencyLevel.lyDuc,
                label: Text('Lý Đức'),
              ),
              ButtonSegment(
                value: ProficiencyLevel.taleb,
                label: Text('Taleb'),
              ),
              ButtonSegment(
                value: ProficiencyLevel.thayBa,
                label: Text('Thầy bà'),
              ),
            ],
            selected: {_proficiencyLevel},
            onSelectionChanged: (Set<ProficiencyLevel> selection) {
              setState(() {
                _proficiencyLevel = selection.first;
              });
              _saveSettings();
            },
          ),
          SizedBox(height: 8),
          Text(
            '**Minh Dế:** Dành cho người mới bắt đầu, cần giải thích các từ cơ bản nhất.\n'
            '**Lý Đức:** Dành cho trình độ trung bình, cần giải thích các từ khó hơn, thành ngữ.\n'
            '**Taleb:** Dành cho trình độ khá/giỏi, cần giải thích từ phức tạp, chuyên ngành, sắc thái nghĩa.\n'
            '**Thầy bà:** Giáo viên hướng dẫn bạn, giải thích cấu trúc, ngữ pháp và ý nghĩa.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  void _saveSettings() {
    widget.onSettingsChanged(
      _geminiApiController.text,
      _perplexityApiController.text,
      _elevenLabsApiController.text,
      _selectedAIService,
      _autoAI,
      _showPhonetics,
      _contextController.text,
      _proficiencyLevel,
    );
  }
}
