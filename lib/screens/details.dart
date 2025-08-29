// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:htr/models/conversion_item.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ConversionDetailScreen extends StatefulWidget {
  final ConversionItem item;

  const ConversionDetailScreen({super.key, required this.item});

  @override
  State<ConversionDetailScreen> createState() => _ConversionDetailScreenState();
}

class _ConversionDetailScreenState extends State<ConversionDetailScreen> {
  late TextEditingController _textController;
  late TextEditingController _titleController;
  bool _isEditingTitle = false;
  bool _hasUnsavedChanges = false;

  // Color palette matching your home screen
  static const Color white = Color(0xFFFFFFFF);
  static const Color richBlack = Color(0xFF00171F);
  static const Color prussianBlue = Color(0xFF003459);
  static const Color cerulean = Color(0xFF007EA7);
  static const Color pictonBlue = Color(0xFF00A8E8);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color redAccent = Color(0xFFE53E3E);

  // Responsive helper
  late bool _isTablet;
  late double _screenWidth;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.recognizedText);
    _titleController = TextEditingController(text: widget.item.title);

    _textController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
  }

  void _initializeResponsiveData() {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _isTablet = _screenWidth > 600;
  }

  // Responsive dimensions
  double get _horizontalPadding => _isTablet ? 24.0 : 16.0;
  double get _cardBorderRadius => _isTablet ? 12.0 : 10.0;
  double get _buttonPadding => _isTablet ? 16.0 : 12.0;
  double get _buttonFontSize => _isTablet ? 16.0 : 14.0;
  double get _titleFontSize => _isTablet ? 20.0 : 18.0;

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardDialog();
      return shouldDiscard ?? false;
    }
    return true;
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardBorderRadius)),
        title: Text(
          'Unsaved Changes',
          style: GoogleFonts.leagueSpartan(
            fontSize: _titleFontSize,
            fontWeight: FontWeight.w600,
            color: richBlack,
          ),
        ),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: GoogleFonts.libreBaskerville(
            fontSize: _isTablet ? 16 : 14,
            color: richBlack.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.libreBaskerville(
                color: cerulean,
                fontWeight: FontWeight.w600,
                fontSize: _buttonFontSize,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Discard',
              style: GoogleFonts.libreBaskerville(
                color: redAccent,
                fontWeight: FontWeight.w600,
                fontSize: _buttonFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    widget.item.recognizedText = _textController.text;
    widget.item.title = _titleController.text.isEmpty
        ? "Untitled Conversion"
        : _titleController.text;
    widget.item.lastModified = DateTime.now();
    await widget.item.save();

    setState(() {
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Changes saved successfully',
            style: GoogleFonts.libreBaskerville(color: white),
          ),
          backgroundColor: cerulean,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _deleteConversion() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardBorderRadius)),
        title: Text(
          'Delete Conversion',
          style: GoogleFonts.leagueSpartan(
            fontSize: _titleFontSize,
            fontWeight: FontWeight.w600,
            color: richBlack,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this conversion? This action cannot be undone.',
          style: GoogleFonts.libreBaskerville(
            fontSize: _isTablet ? 16 : 14,
            color: richBlack.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.libreBaskerville(
                color: cerulean,
                fontWeight: FontWeight.w600,
                fontSize: _buttonFontSize,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.libreBaskerville(
                color: redAccent,
                fontWeight: FontWeight.w600,
                fontSize: _buttonFontSize,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await widget.item.delete();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(_cardBorderRadius + 8)),
        ),
        padding: EdgeInsets.all(_horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _isTablet ? 50 : 40,
              height: 4,
              decoration: BoxDecoration(
                color: richBlack.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: _isTablet ? 20 : 16),
            Text(
              'Export Options',
              style: GoogleFonts.leagueSpartan(
                fontSize: _titleFontSize,
                fontWeight: FontWeight.w600,
                color: richBlack,
              ),
            ),
            SizedBox(height: _isTablet ? 16 : 12),
            _buildExportOption(
              icon: Icons.picture_as_pdf,
              title: 'Export as PDF',
              subtitle: 'Save as PDF document',
              onTap: () {
                Navigator.pop(context);
                _exportAsPDF();
              },
            ),
            SizedBox(height: _isTablet ? 12 : 8),
            _buildExportOption(
              icon: Icons.description,
              title: 'Export as DOCX',
              subtitle: 'Save as Word document',
              onTap: () {
                Navigator.pop(context);
                _exportAsDOCX();
              },
            ),
            SizedBox(height: _isTablet ? 12 : 8),
            _buildExportOption(
              icon: Icons.text_snippet,
              title: 'Export as TXT',
              subtitle: 'Save as plain text',
              onTap: () {
                Navigator.pop(context);
                _exportAsTxt();
              },
            ),
            SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom +
                    (_isTablet ? 16 : 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isTablet ? 16 : 12,
          vertical: _isTablet ? 8 : 4,
        ),
        leading: Container(
          padding: EdgeInsets.all(_isTablet ? 10 : 8),
          decoration: BoxDecoration(
            color: cerulean.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_isTablet ? 8 : 6),
          ),
          child: Icon(icon, color: cerulean, size: _isTablet ? 24 : 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.libreBaskerville(
            fontSize: _buttonFontSize,
            fontWeight: FontWeight.w600,
            color: richBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.libreBaskerville(
            fontSize: _isTablet ? 14 : 12,
            color: richBlack.withOpacity(0.6),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: _isTablet ? 16 : 14),
        onTap: onTap,
      ),
    );
  }

  Future<void> _exportAsPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  widget.item.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  _textController.text,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.item.title}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Here is your converted document as PDF!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: redAccent,
          ),
        );
      }
    }
  }

  Future<void> _exportAsDOCX() async {
    // For now, we'll export as a simple text file with .docx extension
    // In a real app, you'd use a proper DOCX library like docx_template
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.item.title}.docx');

      // Simple RTF format that Word can read
      final rtfContent =
          '''{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}}
\\f0\\fs24 ${widget.item.title}\\par
\\par
${_textController.text.replaceAll('\n', '\\par\n')}
}''';

      await file.writeAsString(rtfContent);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Here is your converted document as DOCX!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting DOCX: $e'),
            backgroundColor: redAccent,
          ),
        );
      }
    }
  }

  Future<void> _exportAsTxt() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.item.title}.txt');
      await file.writeAsString(_textController.text);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Here is your extracted text!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting TXT: $e'),
            backgroundColor: redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeResponsiveData();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: white,
        appBar: AppBar(
          backgroundColor: white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: richBlack, size: _isTablet ? 24 : 22),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: _isEditingTitle
              ? SizedBox(
                  width: _screenWidth * 0.6,
                  child: TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: _titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: richBlack,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) {
                      setState(() {
                        _isEditingTitle = false;
                      });
                    },
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditingTitle = true;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _titleController.text.isEmpty
                                ? 'Untitled Conversion'
                                : _titleController.text,
                            style: GoogleFonts.leagueSpartan(
                              fontSize: _titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: richBlack,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: _isTablet ? 18 : 16,
                          color: richBlack.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ),
          centerTitle: true,
          actions: [
            if (_isEditingTitle)
              IconButton(
                icon: Icon(Icons.check,
                    color: cerulean, size: _isTablet ? 24 : 22),
                onPressed: () {
                  setState(() {
                    _isEditingTitle = false;
                  });
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(_horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Original image preview
              if (File(widget.item.imagePath).existsSync()) ...[
                Container(
                  constraints: BoxConstraints(
                    maxHeight: _isTablet ? 300 : 200,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_cardBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: richBlack.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_cardBorderRadius),
                    child: Image.file(
                      File(widget.item.imagePath),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: _isTablet ? 20 : 16),
              ],

              // Text editor
              Container(
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(_cardBorderRadius),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  minLines: _isTablet ? 12 : 8,
                  style: GoogleFonts.libreBaskerville(
                    fontSize: _isTablet ? 16 : 14,
                    color: richBlack,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your converted text appears here...',
                    hintStyle: GoogleFonts.libreBaskerville(
                      fontSize: _isTablet ? 16 : 14,
                      color: richBlack.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(_isTablet ? 16 : 12),
                  ),
                ),
              ),

              SizedBox(height: _isTablet ? 24 : 20),

              // Action buttons row
              Row(
                children: [
                  // Save Changes
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _hasUnsavedChanges ? _saveChanges : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasUnsavedChanges
                            ? cerulean
                            : cerulean.withOpacity(0.6),
                        foregroundColor: white,
                        padding: EdgeInsets.symmetric(vertical: _buttonPadding),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(_cardBorderRadius),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.libreBaskerville(
                          fontSize: _buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: _isTablet ? 12 : 8),

                  // Export
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showExportOptions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: prussianBlue,
                        foregroundColor: white,
                        padding: EdgeInsets.symmetric(vertical: _buttonPadding),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(_cardBorderRadius),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Export',
                        style: GoogleFonts.libreBaskerville(
                          fontSize: _buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: _isTablet ? 12 : 8),

                  // Delete
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _deleteConversion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redAccent,
                        foregroundColor: white,
                        padding: EdgeInsets.symmetric(vertical: _buttonPadding),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(_cardBorderRadius),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.libreBaskerville(
                          fontSize: _buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: _isTablet ? 20 : 16),
            ],
          ),
        ),
      ),
    );
  }
}
