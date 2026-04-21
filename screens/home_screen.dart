import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note_model.dart';
import '../helpers/database_helper.dart';
import '../providers/theme_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/drawer_widget.dart';
import 'note_editor.dart';
import 'settings_screen.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  List<NoteModel> _notes = [];
  List<NoteModel> _filteredNotes = [];
  final Set<int> _selectedIds = {};
  bool _isSelecting = false;
  bool _isSearching = false;
  int _drawerIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadNotes();
    _fabController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final notes = await _db.getAllNotes();
    setState(() {
      _notes = notes;
      _applyFilter();
    });
  }

  void _applyFilter() {
    List<NoteModel> result = List.from(_notes);
    switch (_drawerIndex) {
      case 0: // All
        break;
      case 1: // Locked
        result = result.where((n) => n.isLocked).toList();
        break;
      case 2: // Pinned
        result = result.where((n) => n.isPinned).toList();
        break;
    }
    _filteredNotes = result;
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      await _loadNotes();
      return;
    }
    final results = await _db.searchNotes(query);
    setState(() => _filteredNotes = results);
  }

  String get _screenTitle {
    switch (_drawerIndex) {
      case 0: return 'My Keep';
      case 1: return 'Locked';
      case 2: return 'Pinned';
      default: return 'My Keep';
    }
  }

  List<NoteModel> get _pinnedNotes =>
      _filteredNotes.where((n) => n.isPinned).toList();
  List<NoteModel> get _unpinnedNotes =>
      _filteredNotes.where((n) => !n.isPinned).toList();

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelecting = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete ${_selectedIds.length} note${_selectedIds.length > 1 ? 's' : ''}?',
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Selected notes will be moved to trash.',
          style: TextStyle(fontFamily: 'Inter'),
        ),
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
    if (confirm == true) {
      for (final id in _selectedIds) {
        await _db.softDeleteNote(id);
      }
      setState(() {
        _selectedIds.clear();
        _isSelecting = false;
      });
      await _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: AppDrawer(
        selectedIndex: _drawerIndex,
        onSelect: (idx) {
          setState(() {
            _drawerIndex = idx;
            if (idx == 99) {
              // Settings
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
                  .then((_) => _loadNotes());
            } else if (idx == 3) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()))
                  .then((_) => _loadNotes());
            } else {
              _applyFilter();
            }
          });
        },
        categories: const [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (_isSelecting)
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textColor),
                      onPressed: () => setState(() {
                        _isSelecting = false;
                        _selectedIds.clear();
                      }),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        _isSearching ? '' : _screenTitle,
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: 28,
                          color: isDark ? const Color(0xFFFFD700) : const Color(0xFF2D2D2D),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (_isSelecting) ...[
                    Text(
                      '${_selectedIds.length} selected',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: _deleteSelected,
                    ),
                  ] else ...[
                    // Search
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: _isSearching ? MediaQuery.of(context).size.width - 120 : 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isSearching
                            ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)]
                            : [],
                      ),
                      child: _isSearching
                          ? Row(
                              children: [
                                const SizedBox(width: 14),
                                Icon(Icons.search_rounded, color: textColor.withOpacity(0.5), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: textColor),
                                    decoration: InputDecoration(
                                      hintText: 'Search notes...',
                                      hintStyle: TextStyle(fontFamily: 'Inter', color: textColor.withOpacity(0.4)),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: _search,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: textColor.withOpacity(0.5), size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _isSearching = false;
                                      _searchController.clear();
                                    });
                                    _loadNotes();
                                  },
                                ),
                              ],
                            )
                          : IconButton(
                              icon: Icon(Icons.search_rounded, color: textColor, size: 22),
                              onPressed: () => setState(() => _isSearching = true),
                            ),
                    ),
                    if (!_isSearching) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.menu_rounded, color: textColor, size: 24),
                        onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // Notes grid
            Expanded(
              child: _filteredNotes.isEmpty
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                      color: const Color(0xFFFFD700),
                      onRefresh: _loadNotes,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Pinned section
                          if (_pinnedNotes.isNotEmpty && _drawerIndex == 0) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                                child: Text(
                                  'PINNED',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color: textColor.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => _buildCard(_pinnedNotes[i]),
                                  childCount: _pinnedNotes.length,
                                ),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.1,
                                ),
                              ),
                            ),
                          ],

                          // Others label
                          if (_pinnedNotes.isNotEmpty && _unpinnedNotes.isNotEmpty && _drawerIndex == 0)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                                child: Text(
                                  'OTHERS',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color: textColor.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),

                          // Main notes
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) {
                                  final list = (_drawerIndex == 0 && _pinnedNotes.isNotEmpty)
                                      ? _unpinnedNotes
                                      : _filteredNotes;
                                  if (i >= list.length) return null;
                                  return _buildCard(list[i]);
                                },
                                childCount: (_drawerIndex == 0 && _pinnedNotes.isNotEmpty)
                                    ? _unpinnedNotes.length
                                    : _filteredNotes.length,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditor()),
          ).then((_) => _loadNotes()),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _buildCard(NoteModel note) {
    return NoteCard(
      note: note,
      isSelected: _selectedIds.contains(note.id),
      onTap: () {
        if (_isSelecting) {
          _toggleSelect(note.id!);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NoteEditor(note: note)),
          ).then((_) => _loadNotes());
        }
      },
      onLongPress: () {
        setState(() {
          _isSelecting = true;
          _selectedIds.add(note.id!);
        });
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 72,
            color: isDark
                ? const Color(0xFF444444)
                : const Color(0xFFDDCCA0),
          ),
          const SizedBox(height: 16),
          Text(
            _drawerIndex == 1 ? 'No locked notes' : 'No notes yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF555555) : const Color(0xFFBBAAAA),
            ),
          ),
          const SizedBox(height: 8),
          if (_drawerIndex == 0)
            Text(
              'Tap + to create one',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDark ? const Color(0xFF444444) : const Color(0xFFCCBB99),
              ),
            ),
        ],
      ),
    );
  }
}
