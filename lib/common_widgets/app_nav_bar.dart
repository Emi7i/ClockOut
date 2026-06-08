import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import 'wave_painter.dart';

/// ─────────────────────────────────────────────────────────────
///  NAV ITEM MODEL
///  Add a new tab by adding a [NavItem] to [AppNavBar.items].
/// ─────────────────────────────────────────────────────────────
class NavItem {
  final IconData icon;
  final String   semanticLabel; // used by screen-readers

  const NavItem({
    required this.icon,
    required this.semanticLabel,
  });
}

// ── Default tab definitions ───────────────────────────────────
//    ← Add / remove / reorder tabs here
const List<NavItem> kDefaultNavItems = [
  NavItem(icon: Icons.access_time_rounded, semanticLabel: 'Clock'),
  NavItem(icon: Icons.menu_rounded,        semanticLabel: 'Menu'),
];

/// ─────────────────────────────────────────────────────────────
///  APP NAV BAR
///  Wavy bottom navigation bar.
///
///  Usage:
///    AppNavBar(
///      selectedIndex: _tab,
///      onItemTapped: (i) => setState(() => _tab = i),
///    )
///
///  To customise tabs pass [items]; defaults to [kDefaultNavItems].
/// ─────────────────────────────────────────────────────────────
class AppNavBar extends StatelessWidget {
  final int                selectedIndex;
  final ValueChanged<int>  onItemTapped;
  final List<NavItem>      items;

  const AppNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.items = kDefaultNavItems,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.navHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Wave background ─────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: const WavePainter()),
          ),

          // ── Tab icons ───────────────────────────────────
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, _buildTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    final bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(
          items[index].icon,
          color: isSelected ? AppColors.accent : AppColors.textMuted,
          size: 26,
          semanticLabel: items[index].semanticLabel,
        ),
      ),
    );
  }
}
