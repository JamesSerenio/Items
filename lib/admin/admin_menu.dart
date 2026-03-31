import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../styles/admin_menu_styles.dart';

enum AdminSection { dashboard, addItems }

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
            text: 'DATA',
            style: TextStyle(color: AdminMenuStyles.textPrimary),
          ),
          TextSpan(
            text: 'CORE',
            style: TextStyle(color: AdminMenuStyles.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage(bool isMobile) {
    switch (_selectedSection) {
      case AdminSection.dashboard:
        return _DashboardView(isMobile: isMobile);
      case AdminSection.addItems:
        return _AddItemsView(isMobile: isMobile);
    }
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
          _SidebarMenuTile(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isCollapsed: _isCollapsed,
            isActive: _selectedSection == AdminSection.dashboard,
            onTap: () => _selectSection(AdminSection.dashboard),
          ),
          const SizedBox(height: 12),
          _SidebarMenuTile(
            icon: Icons.add_box_outlined,
            label: 'Add Items',
            isCollapsed: _isCollapsed,
            isActive: _selectedSection == AdminSection.addItems,
            onTap: () => _selectSection(AdminSection.addItems),
          ),
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
          _SidebarMenuTile(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isCollapsed: false,
            isActive: _selectedSection == AdminSection.dashboard,
            onTap: () {
              _selectSection(AdminSection.dashboard);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _SidebarMenuTile(
            icon: Icons.add_box_outlined,
            label: 'Add Items',
            isCollapsed: false,
            isActive: _selectedSection == AdminSection.addItems,
            onTap: () {
              _selectSection(AdminSection.addItems);
              Navigator.pop(context);
            },
          ),
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

class _DashboardView extends StatelessWidget {
  final bool isMobile;

  const _DashboardView({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isMobile
          ? AdminMenuStyles.mobilePanelDecoration
          : AdminMenuStyles.panelDecoration,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: isMobile
                  ? AdminMenuStyles.pageTitleMobileStyle
                  : AdminMenuStyles.pageTitleStyle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Overview of your admin panel.',
              style: AdminMenuStyles.pageSubtitleStyle,
            ),
            const SizedBox(height: 18),
            if (isMobile) ...[
              const _StatCard(
                title: 'Total Revenue',
                value: '\$2.45M',
                glowColor: AdminMenuStyles.primaryColor,
              ),
              const SizedBox(height: 12),
              const _StatCard(
                title: 'Active Users',
                value: '48.3K',
                glowColor: Color(0xFF34D399),
              ),
              const SizedBox(height: 12),
              const _StatCard(
                title: 'Orders',
                value: '1,284',
                glowColor: AdminMenuStyles.secondaryColor,
              ),
              const SizedBox(height: 14),
              const _BigPanel(
                title: 'Sales Overview',
                subtitle: 'Analytics panel placeholder',
                height: 220,
              ),
              const SizedBox(height: 14),
              const _BigPanel(
                title: 'Recent Activity',
                subtitle: 'Recent logs placeholder',
                height: 220,
              ),
            ] else ...[
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Revenue',
                      value: '\$2.45M',
                      glowColor: AdminMenuStyles.primaryColor,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Active Users',
                      value: '48.3K',
                      glowColor: Color(0xFF34D399),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Orders',
                      value: '1,284',
                      glowColor: AdminMenuStyles.secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(
                    flex: 2,
                    child: _BigPanel(
                      title: 'Sales Overview',
                      subtitle: 'Analytics panel placeholder',
                      height: 420,
                    ),
                  ),
                  SizedBox(width: 18),
                  Expanded(
                    child: _BigPanel(
                      title: 'Recent Activity',
                      subtitle: 'Recent logs placeholder',
                      height: 420,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddItemsView extends StatelessWidget {
  final bool isMobile;

  const _AddItemsView({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isMobile
          ? AdminMenuStyles.mobilePanelDecoration
          : AdminMenuStyles.panelDecoration,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Items',
              style: isMobile
                  ? AdminMenuStyles.pageTitleMobileStyle
                  : AdminMenuStyles.pageTitleStyle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your product or item details here.',
              style: AdminMenuStyles.pageSubtitleStyle,
            ),
            const SizedBox(height: 20),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10172F),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AdminMenuStyles.borderColor,
                      width: 1.1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _InputField(
                        label: 'Item Name',
                        hintText: 'Enter item name',
                        icon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(height: 16),
                      const _InputField(
                        label: 'Price',
                        hintText: 'Enter price',
                        icon: Icons.payments_outlined,
                      ),
                      const SizedBox(height: 16),
                      const _InputField(
                        label: 'Description',
                        hintText: 'Enter description',
                        icon: Icons.description_outlined,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: AdminMenuStyles.logoutButtonStyle,
                          child: const Text(
                            'Save Item',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final int maxLines;

  const _InputField({
    required this.label,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AdminMenuStyles.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          maxLines: maxLines,
          style: const TextStyle(color: AdminMenuStyles.textPrimary),
          decoration: AdminMenuStyles.inputDecoration(
            hintText: hintText,
            prefixIcon: icon,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color glowColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF111A33),
        border: Border.all(color: AdminMenuStyles.borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AdminMenuStyles.cardTitleStyle),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AdminMenuStyles.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final double height;

  const _BigPanel({
    required this.title,
    required this.subtitle,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF10172F),
        border: Border.all(color: AdminMenuStyles.borderColor, width: 1.1),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AdminMenuStyles.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: AdminMenuStyles.pageSubtitleStyle),
          const Spacer(),
          Center(
            child: Icon(
              Icons.auto_graph_rounded,
              size: 72,
              color: AdminMenuStyles.primaryColor.withOpacity(0.85),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
