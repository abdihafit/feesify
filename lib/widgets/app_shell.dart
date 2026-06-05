import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AppTab {
  const AppTab({required this.label, required this.icon, required this.child});

  final String label;
  final IconData icon;
  final Widget child;
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tabs,
    this.user,
  });

  final String title;
  final String subtitle;
  final List<AppTab> tabs;
  final UserModel? user;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool useSideMenu = MediaQuery.of(context).size.width >= 960;
    final AppTab selectedTab = widget.tabs[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTab.label),
        actions: <Widget>[
          if (widget.user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.user!.fullName} | ${widget.user!.role.toUpperCase()}',
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: useSideMenu ? null : _buildMobileDrawer(context),
      body: Row(
        children: <Widget>[
          if (useSideMenu) _buildSideMenu(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        selectedTab.label,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(child: selectedTab.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    return Container(
      width: 290,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: Color(0xFFE5ECEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _MenuHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            user: widget.user,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: widget.tabs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final AppTab tab = widget.tabs[index];
                final bool isSelected = index == _selectedIndex;
                return Material(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            tab.icon,
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tab.label,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
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
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _authService.signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _MenuHeader(
              title: widget.title,
              subtitle: widget.subtitle,
              user: widget.user,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.tabs.length,
                itemBuilder: (context, index) {
                  final AppTab tab = widget.tabs[index];
                  final bool isSelected = index == _selectedIndex;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.background,
                    leading: Icon(tab.icon),
                    title: Text(tab.label),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedIndex = index);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.title,
    required this.subtitle,
    required this.user,
  });

  final String title;
  final String subtitle;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/branding/school_finance_system.png',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          if (user != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              user!.fullName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('${user!.role.toUpperCase()} | School ID: ${user!.schoolId}'),
          ],
        ],
      ),
    );
  }
}
