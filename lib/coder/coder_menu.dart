import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../styles/admin_menu_styles.dart';
import 'add_items.dart';
import 'product.dart';
import 'order.dart';
import 'attachments.dart';

enum CoderSection { addItems, product, order, attachments }

class CoderMenu extends StatefulWidget {
  const CoderMenu({super.key});

  @override
  State<CoderMenu> createState() => _CoderMenuState();
}

class _CoderMenuState extends State<CoderMenu>
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;
  CoderSection _selectedSection = CoderSection.addItems;

  late final AnimationController _brandController;

  @override
  void initState() {
    super.initState();
    _brandController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _brandController.dispose();
    super.dispose();
  }

  void _selectSection(CoderSection section) {
    setState(() => _selectedSection = section);
  }

  void _toggleSidebar() {
    setState(() => _isCollapsed = !_isCollapsed);
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget _buildBrand({bool mobile = false}) {
    final collapsed = _isCollapsed && !mobile;

    if (collapsed) return const SizedBox.shrink();

    return SizedBox(
      height: 58,
      child: AnimatedBuilder(
        animation: _brandController,
        builder: (context, _) {
          final glow = 0.35 + (_brandController.value * 0.35);

          return Padding(
            padding: const EdgeInsets.only(top: 19),
            child: RichText(
              text: TextSpan(
                style: AdminMenuStyles.brandTextStyle,
                children: [
                  TextSpan(
                    text: 'MEGA ',
                    style: AdminMenuStyles.brandMegaTextStyle.copyWith(
                      shadows: [
                        Shadow(
                          color: AdminMenuStyles.megaGreen.withOpacity(glow),
                          blurRadius: 9,
                        ),
                      ],
                    ),
                  ),
                  TextSpan(
                    text: 'PLUTO',
                    style: AdminMenuStyles.brandPlutoTextStyle.copyWith(
                      shadows: [
                        Shadow(
                          color: AdminMenuStyles.plutoGold.withOpacity(glow),
                          blurRadius: 9,
                        ),
                      ],
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

  Widget _buildCurrentPage(bool isMobile) {
    switch (_selectedSection) {
      case CoderSection.addItems:
        return const AddItemsPage();
      case CoderSection.product:
        return const ProductPage();
      case CoderSection.order:
        return const OrderPage();
      case CoderSection.attachments:
        return const AttachmentsPage();
    }
  }

  Widget _menuTiles({required bool isMobile}) {
    return Column(
      children: [
        _SidebarMenuTile(
          icon: Icons.add_box_outlined,
          label: 'Add Items',
          isCollapsed: isMobile ? false : _isCollapsed,
          isActive: _selectedSection == CoderSection.addItems,
          onTap: () {
            _selectSection(CoderSection.addItems);
            if (isMobile) Navigator.pop(context);
          },
        ),
        const SizedBox(height: 12),
        _SidebarMenuTile(
          icon: Icons.inventory_2_outlined,
          label: 'Product',
          isCollapsed: isMobile ? false : _isCollapsed,
          isActive: _selectedSection == CoderSection.product,
          onTap: () {
            _selectSection(CoderSection.product);
            if (isMobile) Navigator.pop(context);
          },
        ),
        const SizedBox(height: 12),
        _SidebarMenuTile(
          icon: Icons.shopping_cart_outlined,
          label: 'Orders',
          isCollapsed: isMobile ? false : _isCollapsed,
          isActive: _selectedSection == CoderSection.order,
          onTap: () {
            _selectSection(CoderSection.order);
            if (isMobile) Navigator.pop(context);
          },
        ),
        const SizedBox(height: 12),
        _SidebarMenuTile(
          icon: Icons.attach_file_rounded,
          label: 'Attachments',
          isCollapsed: isMobile ? false : _isCollapsed,
          isActive: _selectedSection == CoderSection.attachments,
          onTap: () {
            _selectSection(CoderSection.attachments);
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
            height: 58,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _toggleSidebar,
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AdminMenuStyles.textPrimary,
                    size: 28,
                  ),
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(child: _buildBrand()),
                ],
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
                color: AdminMenuStyles.plutoGold,
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
            height: 58,
            child: Row(
              children: [
                Expanded(child: _buildBrand(mobile: true)),
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

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
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: AdminMenuStyles.textPrimary),
            titleSpacing: 0,
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Container(
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
                      key: ValueKey<CoderSection>(_selectedSection),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
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
                        ? AdminMenuStyles.plutoGold
                        : AdminMenuStyles.textSecondary,
                    size: 24,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: isActive
                          ? AdminMenuStyles.plutoGold
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
