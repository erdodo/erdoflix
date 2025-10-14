import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class NavBar extends StatefulWidget {
  final int focusedIndex;
  final Function(int) onFocusChanged;
  final bool isFocused;

  const NavBar({
    Key? key,
    required this.focusedIndex,
    required this.onFocusChanged,
    required this.isFocused,
  }) : super(key: key);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  final List<NavItem> _navItems = [
    NavItem(icon: Icons.home, label: 'Anasayfa', route: '/'),
    NavItem(icon: Icons.movie, label: 'Filmler', route: '/'),
    NavItem(icon: Icons.tv, label: 'Diziler', route: '/'),
    NavItem(icon: Icons.search, label: 'Arama', route: '/'),
    NavItem(icon: Icons.person, label: 'Profil', route: '/'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return _buildMobileNavBar();
    } else {
      return _buildDesktopNavBar();
    }
  }

  Widget _buildMobileNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_navItems.length, (index) {
          return _buildNavButton(
            item: _navItems[index],
            index: index,
            isMobile: true,
          );
        }),
      ),
    );
  }

  Widget _buildDesktopNavBar() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(2, 0), // Sağdan sola gölge
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_navItems.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: _buildNavButton(
              item: _navItems[index],
              index: index,
              isMobile: false,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavButton({
    required NavItem item,
    required int index,
    required bool isMobile,
  }) {
    final isSelected = widget.isFocused && widget.focusedIndex == index;

    return GestureDetector(
      onTap: () {
        widget.onFocusChanged(index);
        if (item.route.isNotEmpty) {
          context.go(item.route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final String route;

  NavItem({required this.icon, required this.label, required this.route});
}
