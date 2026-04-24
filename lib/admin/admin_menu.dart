import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../styles/admin_menu_styles.dart';
import 'dashboard.dart';
import 'add_items.dart';
import 'product.dart';

enum AdminSection { dashboard, addItems, product }

class AdminMenu extends StatefulWidget {
  const AdminMenu({super.key});

  @override
  State<AdminMenu> createState() => _AdminMenuState();
}

class _AdminMenuState extends State<AdminMenu> {
  bool _isCollapsed = false;
  AdminSection _selectedSection = AdminSection.dashboard;

  void _selectSection(AdminSection section) {
    setState(() {
      _selectedSection = section;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget _buildBrand() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
        children: [
          TextSpan(
            text: 'MEGA',
            style: TextStyle(color: AdminMenuStyles.textPrimary),
          ),
          TextSpan(
            text: 'PLUTO',
            style: TextStyle(color: AdminMenuStyles.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage(bool isMobile) {
    switch (_selectedSection) {
      case AdminSection.dashboard:
        return const DashboardPage();
      case AdminSection.addItems:
        return const AddItemsPage();
      case AdminSection.product:
        return const ProductPage();
    }
  }

  Widget _menuTiles({required bool isMobile}) {
    return Column(
      children: [
        _SidebarMenuTile(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          isCollapsed: isMobile ? false : _isCollapsed,
          isActive: _selectedSection == AdminSection.dashboard,
          onTap: () {
            _selectSection(AdminSection.dashboard);
            if (isMobile) Navigator.pop(context);
          },
        ),
        const SizedBox(height: 12),
        _SidebarMenuTile(
          icon: Icons.add_box_outlined,
          label: 'Add Items',
          isCollapsed: isMobile ? false : _isCollapsed,
          isActive: _selectedSection == AdminSection.addItems,
          onTap: () {
            _selectSection(AdminSection.addItems);
            if (isMobile) Navigator.pop(context);
          },
        ),
        const SizedBox(height: 12),
        _SidebarMenuTile(
          icon: Icons.inventory_2_outlined,
          label: 'Product',
          isCollapsed: isMobile ? false : _isCollapsed,
          isActive: _selectedSection == AdminSection.product,
          onTap: () {
            _selectSection(AdminSection.product);
            if (isMobile) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: _isCollapsed ? 96 : 270,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(16),
      decoration: AdminMenuStyles.sidebarDecoration,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: _isCollapsed
                ? Center(
                    child: IconButton(
                      onPressed: _toggleSidebar,
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: AdminMenuStyles.textPrimary,
                        size: 28,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      IconButton(
                        onPressed: _toggleSidebar,
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: AdminMenuStyles.textPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildBrand(),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 26),
          _menuTiles(isMobile: false),
          const Spacer(),
          if (_isCollapsed)
            IconButton(
              onPressed: _logout,
              icon: const Icon(
                Icons.logout_rounded,
                color: AdminMenuStyles.primaryColor,
                size: 28,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: AdminMenuStyles.logoutButtonStyle,
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AdminMenuStyles.sidebarDecoration,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildBrand(),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AdminMenuStyles.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _menuTiles(isMobile: true),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: AdminMenuStyles.logoutButtonStyle,
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 768;

    if (isMobile) {
      return Container(
        decoration: AdminMenuStyles.pageBackground,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          drawerScrimColor: Colors.black54,
          drawer: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _buildMobileSidebar(),
              ),
            ),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: AdminMenuStyles.textPrimary),
            titleSpacing: 0,
            title: _buildBrand(),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: AdminMenuStyles.pageBackground,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildCurrentPage(true),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: AdminMenuStyles.pageBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              _buildDesktopSidebar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 18, 18, 18),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: KeyedSubtree(
                      key: ValueKey<AdminSection>(_selectedSection),
                      child: _buildCurrentPage(false),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCollapsed;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarMenuTile({
    required this.icon,
    required this.label,
    required this.isCollapsed,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : 16,
            vertical: 16,
          ),
          decoration: isActive
              ? AdminMenuStyles.activeMenuDecoration
              : AdminMenuStyles.inactiveMenuDecoration,
          child: isCollapsed
              ? Center(
                  child: Icon(
                    icon,
                    color: isActive
                        ? AdminMenuStyles.primaryColor
                        : AdminMenuStyles.textSecondary,
                    size: 24,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: isActive
                          ? AdminMenuStyles.primaryColor
                          : AdminMenuStyles.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: isActive
                            ? AdminMenuStyles.menuTextStyle
                            : AdminMenuStyles.menuInactiveTextStyle,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
