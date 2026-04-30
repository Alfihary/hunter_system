import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Layout principal con barra inferior personalizada.
///
/// ¿Qué hace?
/// Mantiene una navegación fija entre los módulos principales:
/// INICIO, ENTRENO, DIETA, HÁBITOS, STATS y PERFIL.
///
/// ¿Para qué sirve?
/// Para que la app se sienta más como una experiencia RPG móvil
/// tipo Hunter System / Solo Leveling / Diablo.
class HunterShellScreen extends StatelessWidget {
  final Widget child;

  const HunterShellScreen({super.key, required this.child});

  static const _tabs = <_HunterTab>[
    _HunterTab(
      label: 'INICIO',
      path: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    _HunterTab(
      label: 'ENTRENO',
      path: '/workouts',
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
    ),
    _HunterTab(
      label: 'DIETA',
      path: '/nutrition',
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant,
    ),
    _HunterTab(
      label: 'HÁBITOS',
      path: '/habits',
      icon: Icons.check_circle_outline,
      activeIcon: Icons.check_circle,
    ),
    _HunterTab(
      label: 'STATS',
      path: '/stats',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
    ),
    _HunterTab(
      label: 'PERFIL',
      path: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedIndexForPath(currentPath);

    return Scaffold(
      body: child,
      bottomNavigationBar: _HunterBottomNavBar(
        selectedIndex: selectedIndex,
        tabs: _tabs,
        onSelected: (index) {
          final targetPath = _tabs[index].path;

          if (targetPath != currentPath) {
            context.go(targetPath);
          }
        },
      ),
    );
  }

  /// Calcula qué tab debe aparecer activo según la ruta actual.
  int _selectedIndexForPath(String path) {
    if (path.startsWith('/workouts')) return 1;
    if (path.startsWith('/nutrition')) return 2;
    if (path.startsWith('/habits')) return 3;
    if (path.startsWith('/stats') || path.startsWith('/rpg')) return 4;
    if (path.startsWith('/profile')) return 5;

    return 0;
  }
}

/// Barra inferior personalizada estilo RPG.
class _HunterBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_HunterTab> tabs;
  final ValueChanged<int> onSelected;

  const _HunterBottomNavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF55C8FF);
    const inactiveColor = Color(0xFF4E4D73);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              for (int index = 0; index < tabs.length; index++)
                Expanded(
                  child: _HunterBottomNavItem(
                    tab: tabs[index],
                    isSelected: selectedIndex == index,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item individual de la barra inferior.
class _HunterBottomNavItem extends StatelessWidget {
  final _HunterTab tab;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _HunterBottomNavItem({
    required this.tab,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? tab.activeIcon : tab.icon,
            color: color,
            size: isSelected ? 28 : 25,
          ),
          const SizedBox(height: 4),
          Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Configuración interna de cada pestaña principal.
class _HunterTab {
  final String label;
  final String path;
  final IconData icon;
  final IconData activeIcon;

  const _HunterTab({
    required this.label,
    required this.path,
    required this.icon,
    required this.activeIcon,
  });
}
