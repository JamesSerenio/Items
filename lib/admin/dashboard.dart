import 'package:flutter/material.dart';
import '../styles/dashboard_styles.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: DashboardStyles.pageBackground,
      child: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
          gradient: const LinearGradient(
            colors: [Color(0xFF0B1B13), Color(0xFF13140C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: DashboardStyles.plutoGold.withOpacity(0.85),
            width: 1.25,
          ),
          boxShadow: [
            BoxShadow(
              color: DashboardStyles.plutoGold.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: isMobile
                    ? DashboardStyles.pageTitleMobileStyle
                    : DashboardStyles.pageTitleStyle,
              ),
              const SizedBox(height: 8),
              const Text(
                'Overview of your admin panel.',
                style: DashboardStyles.pageSubtitleStyle,
              ),
              const SizedBox(height: 18),

              if (isMobile) ...[
                const _StatCard(
                  title: 'Total Revenue',
                  value: '\$2.45M',
                  glowColor: DashboardStyles.plutoGold,
                ),
                const SizedBox(height: 12),
                const _StatCard(
                  title: 'Active Users',
                  value: '48.3K',
                  glowColor: DashboardStyles.megaGreen,
                ),
                const SizedBox(height: 12),
                const _StatCard(
                  title: 'Orders',
                  value: '1,284',
                  glowColor: DashboardStyles.plutoGold,
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
                const Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Revenue',
                        value: '\$2.45M',
                        glowColor: DashboardStyles.plutoGold,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Active Users',
                        value: '48.3K',
                        glowColor: DashboardStyles.megaGreen,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Orders',
                        value: '1,284',
                        glowColor: DashboardStyles.plutoGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
      ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: DashboardStyles.cardColor,
        border: Border.all(
          color: DashboardStyles.plutoGold.withOpacity(0.85),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(color: glowColor.withOpacity(0.13), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DashboardStyles.cardTitleStyle),
          const SizedBox(height: 10),
          Text(value, style: DashboardStyles.cardValueStyle),
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
        color: DashboardStyles.panelCardColor,
        border: Border.all(
          color: DashboardStyles.plutoGold.withOpacity(0.85),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardStyles.plutoGold.withOpacity(0.08),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DashboardStyles.panelTitleStyle),
          const SizedBox(height: 8),
          Text(subtitle, style: DashboardStyles.pageSubtitleStyle),
          const Spacer(),
          Center(
            child: Icon(
              Icons.auto_graph_rounded,
              size: 72,
              color: DashboardStyles.plutoGold.withOpacity(0.85),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
