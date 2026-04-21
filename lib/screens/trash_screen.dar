import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/note_model.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({Key? key}) : super(key: key);

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<NoteModel> _trashNotes = [];

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    final notes = await _db.getTrashNotes();
    setState(() => _trashNotes = notes);
  }

  Future<void> _restore(NoteModel note) async {
    await _db.restoreNote(note.id!);
    await _loadTrash();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note restored', style: TextStyle(fontFamily: 'Inter')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF2D2D2D),
        ),
      );
    }
  }

  Future<void> _permanentDelete(NoteModel note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Forever?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        content: const Text('This note will be permanently deleted.', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Inter', color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.permanentDeleteNote(note.id!);
      await _loadTrash();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subColor = isDark ? const Color(0xFF888888) : const Color(0xFF999999);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Trash'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_trashNotes.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: Colors.red.withOpacity(0.8), size: 24),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Empty Trash?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                    content: const Text('All notes will be permanently deleted.', style: TextStyle(fontFamily: 'Inter')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter', color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Empty', style: TextStyle(fontFamily: 'Inter', color: Colors.red, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _db.emptyTrash();
                  await _loadTrash();
                }
              },
            ),
        ],
      ),
      body: _trashNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 72,
                      color: isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD)),
                  const SizedBox(height: 16),
                  Text('Trash is empty', style: TextStyle(
                    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF555555) : const Color(0xFFBBBBBB),
                  )),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _trashNotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final note = _trashNotes[i];
                final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 8),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    subtitle: note.content.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: subColor,
                              ),
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.restore_rounded, color: const Color(0xFFFFD700), size: 22),
                          onPressed: () => _restore(note),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_forever_rounded, color: Colors.red.withOpacity(0.7), size: 22),
                          onPressed: () => _permanentDelete(note),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
