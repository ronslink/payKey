import 'package:flutter/material.dart';
import '../constants/settings_constants.dart';
import '../models/setting_item.dart';

/// Section label for settings groups
class SettingsSectionLabel extends StatelessWidget {
  final String label;

  const SettingsSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SettingsTheme.pagePadding,
        SettingsTheme.sectionLabelTopPadding,
        SettingsTheme.pagePadding,
        SettingsTheme.sectionLabelBottomPadding,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Card containing a list of setting items
class SettingsCard extends StatelessWidget {
  final List<SettingItem> items;

  const SettingsCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SettingsTheme.pagePadding),
      decoration: SettingsTheme.cardDecoration(context),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              SettingTile(item: item),
              if (index < items.length - 1)
                Divider(height: 1, indent: 56, color: Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Individual setting tile within a card
class SettingTile extends StatelessWidget {
  final SettingItem item;

  const SettingTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(SettingsTheme.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SettingsTheme.tilePaddingHorizontal,
            vertical: SettingsTheme.tilePaddingVertical,
          ),
          child: Row(
            children: [
              _buildIconContainer(context),
              const SizedBox(width: 14),
              Expanded(child: _buildTextColumn(context)),
              _buildTrailing(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(BuildContext context) {
    final iconColor = item.iconColor ?? Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        item.icon,
        color: iconColor,
        size: SettingsTheme.settingIconSize,
      ),
    );
  }

  Widget _buildTextColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: item.titleColor ?? Colors.grey.shade900,
          ),
        ),
        if (item.subtitle != null)
          Text(
            item.subtitle!,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (item.hasCustomTrailing) {
      return item.trailing!;
    }

    if (item.isTappable) {
      return Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
        size: 22,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Quick access grid item
class QuickAccessTile extends StatelessWidget {
  final QuickAccessItem item;
  final VoidCallback onTap;

  const QuickAccessTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SettingsTheme.cardBackground,
          borderRadius: BorderRadius.circular(SettingsTheme.cardBorderRadius),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: SettingsTheme.quickAccessIconSize,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of quick access items
class QuickAccessGrid extends StatelessWidget {
  final List<QuickAccessItem> items;
  final void Function(String route) onItemTap;

  const QuickAccessGrid({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SettingsTheme.pagePadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: SettingsTheme.quickAccessColumns,
          childAspectRatio: 1.0,
          crossAxisSpacing: SettingsTheme.quickAccessSpacing,
          mainAxisSpacing: SettingsTheme.quickAccessSpacing,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return QuickAccessTile(
            item: item,
            onTap: () => onItemTap(item.route),
          );
        },
      ),
    );
  }
}

/// Profile header card with gradient background
class ProfileCard extends StatelessWidget {
  final String tier;
  final VoidCallback onEditTap;

  const ProfileCard({
    super.key,
    required this.tier,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.all(SettingsTheme.pagePadding),
      padding: const EdgeInsets.all(SettingsTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: SettingsTheme.profileGradient(primaryColor),
        borderRadius: BorderRadius.circular(SettingsTheme.profileCardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(child: _buildInfo()),
          _buildEditButton(context),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: SettingsTheme.iconContainerSize,
      height: SettingsTheme.iconContainerSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(SettingsTheme.iconContainerRadius),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 28),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tier.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return GestureDetector(
      onTap: onEditTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
      ),
    );
  }
}
