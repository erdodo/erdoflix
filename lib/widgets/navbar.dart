import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../utils/app_theme.dart';

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
    NavItem(icon: Icons.search, label: 'Arama', route: '/search'),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundLight.withOpacity(0.7),
                AppTheme.background.withOpacity(0.9),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            left: true,
            right: true,
            child: Container(
              height: 75,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSmall,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopNavBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppTheme.background.withOpacity(0.9),
                AppTheme.backgroundLight.withOpacity(0.7),
              ],
            ),
            border: Border(
              right: BorderSide(
                color: AppTheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: SafeArea(
            top: true,
            bottom: true,
            left: false,
            right: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: List.generate(_navItems.length, (index) {
                return Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildNavButton(
                      item: _navItems[index],
                      index: index,
                      isMobile: false,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
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
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
        duration: AppTheme.animationMedium,
        curve: AppTheme.animationCurve,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1.0 + (value * 0.1), // Hafif scale efekti
            child: Container(
              width: 64,
              constraints: const BoxConstraints(minHeight: 52, maxHeight: 68),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected ? AppTheme.glowShadow : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    size: isSelected ? 28 : 24,
                  ),
                  const SizedBox(height: AppTheme.spacingXSmall),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: AppTheme.labelSmall.copyWith(
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 10,
                    ),
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

class NavItem {
  final IconData icon;
  final String label;
  final String route;

  NavItem({required this.icon, required this.label, required this.route});
}
