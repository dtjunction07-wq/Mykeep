import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final List<String> categories;

  const AppDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onSelect,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final subColor = isDark ? const Color(0xFF999999) : const Color(0xFF888888);
    final bg = isDark ? const Color(0xFF222222) : Colors.white;
    final activeColor = const Color(0xFFFFD700);

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Name Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Keep',
                    style: TextStyle(
                      fontFamily: 'Pacifico',
                      fontSize: 28,
                      color: isDark ? activeColor : const Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: subColor, size: 22),
                  ),
                ],
              ),
            ),

            // Dark mode toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? activeColor : const Color(0xFFFFAA00),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: themeProvider.toggleTheme,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 46,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: isDark ? activeColor : const Color(0xFFDDDDDD),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 250),
                          alignment: isDark
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE)),
            ),
            const SizedBox(height: 4),

            // Main nav items
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'All Notes',
              isSelected: selectedIndex == 0,
              textColor: textColor,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () {
                onSelect(0);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.lock_rounded,
              label: 'Locked Notes',
              isSelected: selectedIndex == 1,
              textColor: textColor,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () {
                onSelect(1);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.push_pin_rounded,
              label: 'Pinned',
              isSelected: selectedIndex == 2,
              textColor: textColor,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () {
                onSelect(2);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.delete_outline_rounded,
              label: 'Trash',
              isSelected: selectedIndex == 3,
              textColor: textColor,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () {
                onSelect(3);
                Navigator.pop(context);
              },
            ),

            // Categories
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Text(
                  'LABELS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: subColor,
                  ),
                ),
              ),
              ...categories.take(5).map((cat) => _DrawerItem(
                    icon: Icons.label_outline_rounded,
                    label: cat,
                    isSelected: false,
                    textColor: textColor,
                    activeColor: activeColor,
                    isDark: isDark,
                    onTap: () {
                      onSelect(10); // categories start at 10
                      Navigator.pop(context);
                    },
                  )),
            ],

            const Spacer(),

            // Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE)),
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              isSelected: selectedIndex == 99,
              textColor: textColor,
              activeColor: activeColor,
              isDark: isDark,
              onTap: () {
                onSelect(99);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color textColor;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.textColor,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(isDark ? 0.2 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeColor : textColor.withOpacity(0.6),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? activeColor : textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
