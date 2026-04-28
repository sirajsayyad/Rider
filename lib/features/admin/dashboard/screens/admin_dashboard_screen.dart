import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards/cards.dart';

/// Admin dashboard with analytics overview
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final promoBanners = <Map<String, String>>[
      {
        'title': 'Peak Hour Insights',
        'subtitle': 'Live demand zones & surge trends',
        'imageUrl':
            'https://images.unsplash.com/photo-1526662092594-e98c1e356d6a?auto=format&fit=crop&w=1600&q=80',
      },
      {
        'title': 'Driver Quality',
        'subtitle': 'Verify documents faster with smart checks',
        'imageUrl':
            'https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&w=1600&q=80',
      },
      {
        'title': 'Safety & SOS',
        'subtitle': 'Faster response with admin escalation',
        'imageUrl':
            'https://images.unsplash.com/photo-1520975958225-635a3b1b59b9?auto=format&fit=crop&w=1600&q=80',
      },
    ];

    // Demo statistics
    final stats = {
      'totalRides': 12456,
      'activeDrivers': 234,
      'totalPassengers': 5678,
      'todayRevenue': 125680.0,
      'weeklyRevenue': 876540.0,
      'monthlyRevenue': 3245670.0,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Welcome back, Admin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            Text(
              'Here\'s what\'s happening today',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            _DashboardPromoCarousel(
              items: promoBanners,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Revenue overview
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Revenue',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '+12.5%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    Formatters.currency(stats['monthlyRevenue'] as double),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _RevenueChip(
                          label: 'Today',
                          value: Formatters.currency(
                              stats['todayRevenue'] as double),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _RevenueChip(
                          label: 'This Week',
                          value: Formatters.currency(
                              stats['weeklyRevenue'] as double),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Quick stats
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Rides',
                    value: Formatters.compactNumber(
                      (stats['totalRides'] as int).toDouble(),
                    ),
                    icon: Icons.directions_car,
                    iconColor: AppColors.primary,
                    trend: '+8%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    title: 'Active Drivers',
                    value: (stats['activeDrivers'] as int).toString(),
                    icon: Icons.people,
                    iconColor: AppColors.secondary,
                    trend: '+5',
                    isPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Passengers',
                    value: Formatters.compactNumber(
                      (stats['totalPassengers'] as int).toDouble(),
                    ),
                    icon: Icons.person,
                    iconColor: AppColors.success,
                    trend: '+156',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: StatCard(
                    title: 'Pending Issues',
                    value: '12',
                    icon: Icons.warning,
                    iconColor: AppColors.warning,
                    trend: '-3',
                    isPositive: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Recent activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            const _ActivityItem(
              icon: Icons.person_add,
              iconColor: AppColors.success,
              title: 'New driver registered',
              subtitle: 'Raj Kumar - DL 01 AB 1234',
              time: '5 min ago',
            ),
            const _ActivityItem(
              icon: Icons.warning,
              iconColor: AppColors.warning,
              title: 'SOS Alert triggered',
              subtitle: 'Priya Sharma - Trip #12345',
              time: '12 min ago',
            ),
            const _ActivityItem(
              icon: Icons.report,
              iconColor: AppColors.error,
              title: 'Dispute reported',
              subtitle: 'Fare discrepancy - Trip #12340',
              time: '25 min ago',
            ),
            const _ActivityItem(
              icon: Icons.verified,
              iconColor: AppColors.success,
              title: 'Document verified',
              subtitle: 'Amit Singh - Driving License',
              time: '1 hour ago',
            ),

            const SizedBox(height: AppSpacing.xl),

            // Quick actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_circle,
                    label: 'Add Driver',
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.local_offer,
                    label: 'Create Promo',
                    color: AppColors.secondary,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.announcement,
                    label: 'Send Alert',
                    color: AppColors.warning,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 32),
                ),
                SizedBox(height: 12),
                Text(
                  'Serene Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'admin@serene.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            isSelected: true,
            onTap: () => Navigator.pop(context),
          ),
          _DrawerItem(
            icon: Icons.people,
            title: 'Manage Drivers',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.person,
            title: 'Manage Passengers',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.directions_car,
            title: 'Active Rides',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.receipt_long,
            title: 'Transactions',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.local_offer,
            title: 'Promo Codes',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.support_agent,
            title: 'Support Tickets',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.bar_chart,
            title: 'Reports',
            onTap: () {},
          ),
          const Spacer(),
          const Divider(),
          _DrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {},
          ),
          _DrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RevenueChip extends StatelessWidget {
  final String label;
  final String value;

  const _RevenueChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}

class _DashboardPromoCarousel extends StatefulWidget {
  final List<Map<String, String>> items;

  const _DashboardPromoCarousel({
    required this.items,
  });

  @override
  State<_DashboardPromoCarousel> createState() =>
      _DashboardPromoCarouselState();
}

class _DashboardPromoCarouselState extends State<_DashboardPromoCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openPreview(int index) {
    final item = widget.items[index];
    final imageUrl = item['imageUrl'];
    if (imageUrl == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.75),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: Hero(
                        tag: '_admin_promo_$index',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _ShimmerBanner(
                              height: MediaQuery.of(context).size.height * 0.6,
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height * 0.6,
                              color: Colors.black26,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white70,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Highlights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const Spacer(),
            Text(
              '${_index + 1}/${widget.items.length}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final title = item['title'] ?? '';
              final subtitle = item['subtitle'] ?? '';
              final imageUrl = item['imageUrl'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openPreview(index),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: '_admin_promo_$index',
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const _ShimmerBanner(height: 140),
                              errorWidget: (context, url, error) => Container(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.15),
                                  Colors.black.withOpacity(0.65),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            final selected = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: selected ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ShimmerBanner extends StatelessWidget {
  final double height;

  const _ShimmerBanner({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withOpacity(0.6),
      child: Container(
        height: height,
        color: base,
      ),
    );
  }
}
