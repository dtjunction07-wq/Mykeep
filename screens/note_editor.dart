import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../helpers/database_helper.dart';
import 'lock_screen.dart';

class NoteEditor extends StatefulWidget {
  final NoteModel? note;

  const NoteEditor({Key? key, this.note}) : super(key: key);

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedColor;
  late bool _isPinned;
  late bool _isLocked;
  String? _category;
  bool _isUnlocked = false;
  bool _hasChanges = false;
  final DatabaseHelper _db = DatabaseHelper();

  final List<Map<String, dynamic>> _colorOptions = [
    {'hex': '#FFFFFF', 'label': 'White'},
    {'hex': '#FFF9E6', 'label': 'Yellow'},
    {'hex': '#E8F5E9', 'label': 'Green'},
    {'hex': '#FCE4EC', 'label': 'Pink'},
    {'hex': '#E3F2FD', 'label': 'Blue'},
    {'hex': '#F3E5F5', 'label': 'Purple'},
    {'hex': '#FFF3E0', 'label': 'Orange'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedColor = widget.note?.color ?? '#FFFFFF';
    _isPinned = widget.note?.isPinned ?? false;
    _isLocked = widget.note?.isLocked ?? false;
    _category = widget.note?.category;

    // If note is locked and exists, need to unlock first
    if (widget.note != null && widget.note!.isLocked) {
      _isUnlocked = false;
    } else {
      _isUnlocked = true;
    }

    _titleController.addListener(() => _hasChanges = true);
    _contentController.addListener(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final now = DateTime.now();
    if (widget.note == null) {
      final note = NoteModel(
        title: title,
        content: content,
        color: _selectedColor,
        isPinned: _isPinned,
        isLocked: _isLocked,
        category: _category,
        createdAt: now,
        updatedAt: now,
      );
      await _db.insertNote(note);
    } else {
      final updated = widget.note!.copyWith(
        title: title,
        content: content,
        color: _selectedColor,
        isPinned: _isPinned,
        isLocked: _isLocked,
        category: _category,
        updatedAt: now,
      );
      await _db.updateNote(updated);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<bool> _hasPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lock_pin') != null;
  }

  Future<void> _toggleLock() async {
    final hasPinSet = await _hasPinSet();

    if (!_isLocked) {
      // Locking the note
      if (!hasPinSet) {
        // No PIN set — setup first
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _LockScreenSheet(
              mode: LockMode.setup,
              onSuccess: () {
                Navigator.pop(context);
                setState(() => _isLocked = true);
                _showSnack('Note locked');
              },
            ),
          );
        }
      } else {
        // PIN already set — verify then lock
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _LockScreenSheet(
              mode: LockMode.verify,
              onSuccess: () {
                Navigator.pop(context);
                setState(() => _isLocked = true);
                _showSnack('Note locked');
              },
            ),
          );
        }
      }
    } else {
      // Unlocking
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _LockScreenSheet(
            mode: LockMode.verify,
            onSuccess: () {
              Navigator.pop(context);
              setState(() => _isLocked = false);
              _showSnack('Note unlocked');
            },
          ),
        );
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D2D2D),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showColorPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Note Color',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _colorOptions.map((opt) {
                  final hex = opt['hex'] as String;
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = hex);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _hexToColor(hex),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: const Color(0xFFFFD700), width: 3)
                            : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                        boxShadow: isSelected
                            ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 8)]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF2D2D2D))
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: _category ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Set Label',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D2D2D),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isDark ? Colors.white : const Color(0xFF2D2D2D),
          ),
          decoration: InputDecoration(
            hintText: 'Label name...',
            hintStyle: TextStyle(color: isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFFD700)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _category = controller.text.trim().isEmpty ? null : controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(fontFamily: 'Inter', color: Color(0xFFFFD700), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) {
      Navigator.pop(context);
      return;
    }

    if (_isLocked) {
      // Need PIN to delete
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LockScreenSheet(
          mode: LockMode.verify,
          onSuccess: () async {
            Navigator.pop(context);
            await _db.softDeleteNote(widget.note!.id!);
            if (mounted) Navigator.pop(context, true);
          },
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Note', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        content: const Text('Move this note to trash?', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Inter', color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.softDeleteNote(widget.note!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _selectedColor == '#FFFFFF' || _selectedColor == '#ffffff'
        ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF9E6))
        : _hexToColor(_selectedColor);
    final textColor = isDark && (_selectedColor == '#FFFFFF' || _selectedColor == '#ffffff')
        ? Colors.white
        : const Color(0xFF2D2D2D);

    // If locked and not yet unlocked
    if (!_isUnlocked && widget.note != null && widget.note!.isLocked) {
      return LockScreen(
        mode: LockMode.verify,
        onSuccess: () => setState(() => _isUnlocked = true),
        onCancel: () => Navigator.pop(context),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: _saveNote,
        ),
        actions: [
          // Pin
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? const Color(0xFFFFD700) : textColor.withOpacity(0.6),
              size: 22,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          // Lock
          IconButton(
            icon: Icon(
              _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: _isLocked ? const Color(0xFFFFD700) : textColor.withOpacity(0.6),
              size: 22,
            ),
            onPressed: _toggleLock,
          ),
          // Delete
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: textColor.withOpacity(0.6), size: 22),
            onPressed: _deleteNote,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Title field
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  // Divider
                  Divider(color: textColor.withOpacity(0.1), height: 1),
                  const SizedBox(height: 8),
                  // Content field
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        height: 1.6,
                        color: textColor.withOpacity(0.85),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          color: textColor.withOpacity(0.3),
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom toolbar
          Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                top: BorderSide(color: textColor.withOpacity(0.08)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Color picker
                  IconButton(
                    icon: Icon(Icons.palette_outlined, color: textColor.withOpacity(0.6), size: 22),
                    onPressed: _showColorPicker,
                  ),
                  // Label
                  IconButton(
                    icon: Icon(
                      _category != null ? Icons.label_rounded : Icons.label_outline_rounded,
                      color: _category != null ? const Color(0xFFFFD700) : textColor.withOpacity(0.6),
                      size: 22,
                    ),
                    onPressed: _showCategoryDialog,
                  ),
                  // Date info
                  const Spacer(),
                  if (widget.note != null)
                    Text(
                      _formatDate(widget.note!.updatedAt),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: textColor.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// Bottom sheet wrapper for lock screen
class _LockScreenSheet extends StatelessWidget {
  final LockMode mode;
  final VoidCallback onSuccess;

  const _LockScreenSheet({required this.mode, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: LockScreen(
        mode: mode,
        onSuccess: onSuccess,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
