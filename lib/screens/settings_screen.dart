import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import 'lock_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasPIN = false;

  @override
  void initState() {
    super.initState();
    _checkPIN();
  }

  Future<void> _checkPIN() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _hasPIN = prefs.getString('lock_pin') != null);
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

  void _changePIN() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF9E6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: LockScreen(
          mode: _hasPIN ? LockMode.change : LockMode.setup,
          onSuccess: () {
            Navigator.pop(context);
            _checkPIN();
            _showSnack(_hasPIN ? 'PIN updated' : 'PIN set successfully');
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _removePIN() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Verify current PIN first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF9E6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: LockScreen(
          mode: LockMode.verify,
          onSuccess: () async {
            Navigator.pop(context);
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('lock_pin');
            // Unlock all locked notes
            final db = DatabaseHelper();
            final notes = await db.getAllNotes();
            for (final n in notes.where((n) => n.isLocked)) {
              await db.updateNote(n.copyWith(isLocked: false));
            }
            _checkPIN();
            _showSnack('PIN removed. All notes unlocked.');
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _emptyTrash() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Empty Trash', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        content: const Text(
          'All notes in trash will be permanently deleted. This cannot be undone.',
          style: TextStyle(fontFamily: 'Inter'),
        ),
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
      await DatabaseHelper().emptyTrash();
      _showSnack('Trash emptied');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subColor = isDark ? const Color(0xFF888888) : const Color(0xFF999999);
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Lock section
          _SectionHeader(label: 'SECURITY', color: subColor),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: _hasPIN ? 'Change PIN' : 'Set PIN',
                  subtitle: _hasPIN ? 'Update your lock PIN' : 'Set a PIN to lock notes',
                  iconColor: const Color(0xFFFFD700),
                  textColor: textColor,
                  subColor: subColor,
                  onTap: _changePIN,
                ),
                if (_hasPIN) ...[
                  Divider(color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE), height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.lock_open_rounded,
                    title: 'Remove PIN',
                    subtitle: 'This will unlock all locked notes',
                    iconColor: Colors.orange,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: _removePIN,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data section
          _SectionHeader(label: 'DATA', color: subColor),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10),
              ],
            ),
            child: _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Empty Trash',
              subtitle: 'Permanently delete all trashed notes',
              iconColor: Colors.red,
              textColor: textColor,
              subColor: subColor,
              onTap: _emptyTrash,
            ),
          ),

          const SizedBox(height: 32),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  'My Keep',
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 22,
                    color: isDark ? const Color(0xFFFFD700) : const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
