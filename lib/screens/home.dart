// ignore_for_file: unused_field, unused_local_variable, deprecated_member_use, use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:htr/screens/details.dart';
import 'package:image_picker/image_picker.dart';
import 'package:htr/services/text_recognition_service.dart';
import 'package:htr/utils/app_logger.dart';
import 'package:htr/models/conversion_item.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final Box<ConversionItem> box = Hive.box<ConversionItem>('conversions');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Tooltip overlay management
  OverlayEntry? _overlayEntry;
  bool _showingTooltips = false;
  int _currentTooltip = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Global keys for tooltip positioning
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _documentsKey = GlobalKey();

  // Responsive helper
  late bool _isTablet;
  late double _screenWidth;
  late double _screenHeight;
  late EdgeInsets _screenPadding;

  // Color palette
  static const Color white = Color(0xFFFFFFFF);
  static const Color richBlack = Color(0xFF00171F);
  static const Color prussianBlue = Color(0xFF003459);
  static const Color cerulean = Color(0xFF007EA7);
  static const Color pictonBlue = Color(0xFF00A8E8);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeResponsiveData();
      _checkAndShowTooltips();
    });
  }

  void _initializeResponsiveData() {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _screenPadding = mediaQuery.padding;
    _isTablet = _screenWidth > 600;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  // Responsive dimensions
  double get _horizontalPadding => _isTablet ? 32.0 : 24.0;
  double get _cardBorderRadius => _isTablet ? 20.0 : 16.0;
  double get _logoSize => _isTablet ? 64.0 : 56.0;
  double get _searchBarHeight => _isTablet ? 60.0 : 52.0;
  double get _itemImageSize => _isTablet ? 56.0 : 48.0;

  TextStyle get _sectionHeaderStyle => GoogleFonts.leagueSpartan(
        fontSize: _isTablet ? 24 : 20,
        fontWeight: FontWeight.w600,
        color: richBlack,
      );

  Future<void> _checkAndShowTooltips() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTooltips = prefs.getBool('has_seen_tooltips') ?? false;

    if (!hasSeenTooltips && mounted) {
      _showTooltips();
    }
  }

  void _showTooltips() {
    setState(() {
      _showingTooltips = true;
      _currentTooltip = 0;
    });
    _showCurrentTooltip();
  }

  void _showCurrentTooltip() {
    _removeOverlay();

    final tooltips = [
      TooltipData(
        key: _fabKey,
        title: "Add New Conversion",
        message:
            "Tap here to take a photo or choose from gallery to convert handwritten text",
        position: TooltipPosition.smart,
      ),
      TooltipData(
        key: _searchKey,
        title: "Search Your Documents",
        message:
            "Use this search bar to find specific conversions by title or content",
        position: TooltipPosition.smart,
      ),
      TooltipData(
        key: _documentsKey,
        title: "Your Converted Documents",
        message:
            "All your converted documents will appear here. Tap any item to view and edit",
        position: TooltipPosition.smart,
      ),
    ];

    if (_currentTooltip < tooltips.length) {
      _overlayEntry = _createTooltipOverlay(tooltips[_currentTooltip]);
      Overlay.of(context).insert(_overlayEntry!);
      _animationController.forward();
    }
  }

  OverlayEntry _createTooltipOverlay(TooltipData tooltipData) {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _nextTooltip,
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Stack(
                    children: [
                      _buildSpotlight(tooltipData.key),
                      _buildTooltipBubble(tooltipData),
                      _buildSkipButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      top: _screenPadding.top + (_isTablet ? 24 : 16),
      right: _isTablet ? 24 : 16,
      child: TextButton(
        onPressed: _skipTooltips,
        style: TextButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.3),
          padding: EdgeInsets.symmetric(
            horizontal: _isTablet ? 20 : 16,
            vertical: _isTablet ? 12 : 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Skip',
          style: GoogleFonts.libreBaskerville(
            color: white,
            fontSize: _isTablet ? 18 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSpotlight(GlobalKey targetKey) {
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final spotlightPadding = _isTablet ? 16.0 : 12.0;

    return Positioned(
      left: position.dx - spotlightPadding,
      top: position.dy - spotlightPadding,
      child: Container(
        width: size.width + (spotlightPadding * 2),
        height: size.height + (spotlightPadding * 2),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_isTablet ? 16 : 12),
          border: Border.all(
            color: pictonBlue,
            width: _isTablet ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: pictonBlue.withOpacity(0.3),
              blurRadius: _isTablet ? 20 : 15,
              spreadRadius: _isTablet ? 8 : 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipBubble(TooltipData tooltipData) {
    final RenderBox? renderBox =
        tooltipData.key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Smart positioning calculations
    final tooltipWidth = _isTablet
        ? (_screenWidth * 0.6).clamp(400.0, 500.0)
        : (_screenWidth * 0.85).clamp(280.0, 350.0);

    final estimatedHeight = _isTablet ? 180.0 : 160.0;
    final margin = _isTablet ? 24.0 : 16.0;

    // Calculate available space
    final spaceAbove = position.dy - _screenPadding.top - margin;
    final spaceBelow = _screenHeight -
        (position.dy + size.height) -
        _screenPadding.bottom -
        margin;
    final spaceLeft = position.dx - margin;
    final spaceRight = _screenWidth - (position.dx + size.width) - margin;

    // Smart positioning logic
    double left, top;
    bool showAbove = spaceAbove > estimatedHeight || spaceAbove > spaceBelow;

    if (showAbove && spaceAbove > estimatedHeight) {
      // Position above
      top = position.dy - estimatedHeight - margin;
    } else if (spaceBelow > estimatedHeight) {
      // Position below
      top = position.dy + size.height + margin;
    } else {
      // Fallback: position where there's most space
      top = showAbove
          ? (_screenPadding.top + margin)
          : (_screenHeight - estimatedHeight - _screenPadding.bottom - margin);
    }

    // Horizontal centering with bounds checking
    left = (position.dx + size.width / 2) - (tooltipWidth / 2);
    left = left.clamp(margin, _screenWidth - tooltipWidth - margin);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: tooltipWidth,
        constraints: BoxConstraints(
          minHeight: _isTablet ? 160 : 140,
          maxHeight: _screenHeight * 0.4,
        ),
        padding: EdgeInsets.all(_isTablet ? 28 : 24),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(_isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: _isTablet ? 20 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tooltipData.title,
              style: GoogleFonts.leagueSpartan(
                fontSize: _isTablet ? 22 : 18,
                fontWeight: FontWeight.w600,
                color: richBlack,
              ),
            ),
            SizedBox(height: _isTablet ? 16 : 12),
            Flexible(
              child: Text(
                tooltipData.message,
                style: GoogleFonts.libreBaskerville(
                  fontSize: _isTablet ? 16 : 14,
                  color: richBlack.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: _isTablet ? 24 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentTooltip + 1} of 3',
                  style: GoogleFonts.libreBaskerville(
                    fontSize: _isTablet ? 14 : 12,
                    color: richBlack.withOpacity(0.6),
                  ),
                ),
                ElevatedButton(
                  onPressed: _nextTooltip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cerulean,
                    foregroundColor: white,
                    padding: EdgeInsets.symmetric(
                      horizontal: _isTablet ? 28 : 24,
                      vertical: _isTablet ? 14 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_isTablet ? 12 : 10),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _currentTooltip == 2 ? 'Got it!' : 'Next',
                    style: GoogleFonts.libreBaskerville(
                      fontSize: _isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _nextTooltip() {
    _animationController.reverse().then((_) {
      _currentTooltip++;
      if (_currentTooltip < 3) {
        _showCurrentTooltip();
      } else {
        _finishTooltips();
      }
    });
  }

  void _skipTooltips() {
    _animationController.reverse().then((_) {
      _finishTooltips();
    });
  }

  Future<void> _finishTooltips() async {
    _removeOverlay();
    setState(() {
      _showingTooltips = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tooltips', true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(_cardBorderRadius)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                (_isTablet ? 32 : 24),
            top: _isTablet ? 24 : 20,
            left: _horizontalPadding,
            right: _horizontalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _isTablet ? 60 : 40,
                height: 4,
                decoration: BoxDecoration(
                  color: richBlack.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: _isTablet ? 24 : 20),
              _buildBottomSheetOption(
                icon: Icons.camera_alt,
                title: "Take a photo",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              SizedBox(height: _isTablet ? 16 : 12),
              _buildBottomSheetOption(
                icon: Icons.photo_library,
                title: "Choose from gallery",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(_isTablet ? 16 : 12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isTablet ? 24 : 20,
          vertical: _isTablet ? 12 : 8,
        ),
        leading: Container(
          padding: EdgeInsets.all(_isTablet ? 12 : 10),
          decoration: BoxDecoration(
            color: prussianBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_isTablet ? 12 : 10),
          ),
          child: Icon(
            icon,
            color: prussianBlue,
            size: _isTablet ? 28 : 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.libreBaskerville(
            color: richBlack,
            fontSize: _isTablet ? 18 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: richBlack.withOpacity(0.4),
          size: _isTablet ? 20 : 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      // Show loading dialog
      // Do this:
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Conversion in progress, please wait',
                  style: GoogleFonts.libreBaskerville(
                    fontSize: _isTablet ? 16 : 14,
                    color: richBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      try {
        final recognizedText =
            await TextRecognitionService.recognizeText(File(image.path));
        AppLogger.info("Extracted text: $recognizedText");

        final newItem = ConversionItem()
          ..id = DateTime.now().millisecondsSinceEpoch.toString()
          ..imagePath = image.path
          ..recognizedText = recognizedText
          ..title = "Untitled Conversion"
          ..createdAt = DateTime.now()
          ..lastModified = DateTime.now();

        await box.add(newItem);

        // Update dialog to show success state
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showSuccessDialog(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversionDetailScreen(item: newItem),
              ),
            );
          });
        }
      } catch (e) {
        // Handle errors
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          // Show error dialog or handle error appropriately
          AppLogger.error("Conversion failed: $e");
        }
      }
    } else {
      AppLogger.warning("No image selected.");
    }
  }

  void _showSuccessDialog(VoidCallback onComplete) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Conversion complete!',
                style: GoogleFonts.libreBaskerville(
                  fontSize: _isTablet ? 16 : 14,
                  color: richBlack,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // Auto-dismiss after showing success for a brief moment
    Timer(const Duration(milliseconds: 1500), () {
      if (context.mounted) {
        Navigator.of(context).pop();
        onComplete();
      }
    });
  }

  List<ConversionItem> _getFilteredItems() {
    final items = box.values.toList().reversed.toList();
    if (_searchQuery.isEmpty) {
      return items;
    }
    return items.where((item) {
      return item.title.toLowerCase().contains(_searchQuery) ||
          item.recognizedText.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return 'Last Week, ${_formatTime(dateTime)}';
    } else if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday, ${_formatTime(dateTime)}';
      } else {
        return '${difference.inDays} days ago, ${_formatTime(dateTime)}';
      }
    } else {
      return 'Today, ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _getPreviewText(String text) {
    if (text.isEmpty) return 'No text recognized';
    final lines = text.split('\n');
    final firstLine = lines.isNotEmpty ? lines[0] : '';
    final maxLength = _isTablet ? 70 : 50;
    return firstLine.length > maxLength
        ? '${firstLine.substring(0, maxLength)}...'
        : firstLine;
  }

  @override
  Widget build(BuildContext context) {
    // Update responsive data on rebuild (orientation changes)
    _initializeResponsiveData();

    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            SizedBox(height: _isTablet ? 32 : 24),
            _buildSectionHeader(),
            SizedBox(height: _isTablet ? 20 : 16),
            _buildDocumentsList(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(_horizontalPadding),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: _isTablet ? 24 : 20,
          horizontal: _isTablet ? 28 : 24,
        ),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: richBlack.withOpacity(0.08),
              blurRadius: _isTablet ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: _logoSize,
              height: _logoSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_isTablet ? 16 : 12),
                boxShadow: [
                  BoxShadow(
                    color: richBlack.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_isTablet ? 16 : 12),
                child: Image.asset(
                  'assets/appicon_notext.png',
                  width: _logoSize,
                  height: _logoSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: cerulean,
                        borderRadius:
                            BorderRadius.circular(_isTablet ? 16 : 12),
                      ),
                      child: Icon(
                        Icons.text_fields,
                        color: white,
                        size: _logoSize * 0.5,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: _isTablet ? 20 : 16),
            Expanded(
              child: Text(
                "Quill",
                style: TextStyle(
                  fontFamily: 'Roca Two', // matches the family name
                  fontSize: 28,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Container(
        key: _searchKey,
        height: _searchBarHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(_isTablet ? 16 : 12),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.libreBaskerville(
            color: richBlack,
            fontSize: _isTablet ? 18 : 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search conversions...',
            hintStyle: GoogleFonts.libreBaskerville(
              color: richBlack.withOpacity(0.5),
              fontSize: _isTablet ? 18 : 16,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(_isTablet ? 16 : 12),
              child: Icon(
                Icons.search,
                color: richBlack.withOpacity(0.5),
                size: _isTablet ? 28 : 24,
              ),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: _isTablet ? 24 : 20,
              vertical: _isTablet ? 20 : 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Text(
        "Recent Documents",
        key: _documentsKey,
        style: _sectionHeaderStyle,
      ),
    );
  }

  Widget _buildDocumentsList() {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<ConversionItem> box, _) {
          final filteredItems = _getFilteredItems();

          if (filteredItems.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
            itemCount: filteredItems.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: _isTablet ? 16 : 12),
            itemBuilder: (context, index) =>
                _buildDocumentItem(filteredItems[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: _isTablet ? 120 : 80,
            color: richBlack.withOpacity(0.3),
          ),
          SizedBox(height: _isTablet ? 24 : 16),
          Text(
            box.isEmpty ? "No conversions yet." : "No results found.",
            style: GoogleFonts.libreBaskerville(
              fontSize: _isTablet ? 20 : 18,
              color: richBlack.withOpacity(0.6),
            ),
          ),
          if (box.isEmpty) ...[
            SizedBox(height: _isTablet ? 12 : 8),
            Text(
              "Tap the + button to get started",
              style: GoogleFonts.libreBaskerville(
                fontSize: _isTablet ? 16 : 14,
                color: richBlack.withOpacity(0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentItem(ConversionItem item) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: richBlack.withOpacity(0.08),
            blurRadius: _isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(_isTablet ? 20 : 16),
        leading: Container(
          width: _itemImageSize,
          height: _itemImageSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isTablet ? 12 : 8),
            boxShadow: [
              BoxShadow(
                color: richBlack.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isTablet ? 12 : 8),
            child: Image.file(
              File(item.imagePath),
              width: _itemImageSize,
              height: _itemImageSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: Icon(
                    Icons.image_not_supported,
                    color: richBlack.withOpacity(0.3),
                    size: _itemImageSize * 0.5,
                  ),
                );
              },
            ),
          ),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.leagueSpartan(
            fontSize: _isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: richBlack,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: _isTablet ? 6 : 4),
            Text(
              _getPreviewText(item.recognizedText),
              style: GoogleFonts.libreBaskerville(
                fontSize: _isTablet ? 16 : 14,
                color: richBlack.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: _isTablet ? 10 : 8),
            Text(
              _formatTimeAgo(item.lastModified),
              style: GoogleFonts.libreBaskerville(
                fontSize: _isTablet ? 14 : 12,
                color: richBlack.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: richBlack.withOpacity(0.3),
          size: _isTablet ? 24 : 20,
        ),
        onTap: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConversionDetailScreen(item: item),
            ),
          );
          if (shouldRefresh == true) {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      key: _fabKey,
      onPressed: _showImageSourceDialog,
      backgroundColor: cerulean,
      foregroundColor: white,
      elevation: _isTablet ? 8 : 6,
      child: Icon(
        Icons.add,
        size: _isTablet ? 32 : 24,
      ),
    );
  }
}

// Helper classes for tooltip management
class TooltipData {
  final GlobalKey key;
  final String title;
  final String message;
  final TooltipPosition position;

  TooltipData({
    required this.key,
    required this.title,
    required this.message,
    required this.position,
  });
}

enum TooltipPosition {
  top,
  bottom,
  topLeft,
  topCenter,
  smart, // Automatically determines best position
}
