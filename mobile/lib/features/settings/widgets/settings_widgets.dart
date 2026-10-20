import 'package:flutter/material.dart';
import '../../../core/theme/pay_colors.dart';
import '../../../core/widgets/responsive_card_grid.dart';
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
          color: context.textSecondary,
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

  const SettingsCard({super.key, required this.items});

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
                Divider(height: 1, indent: 56, color: context.borderMuted),
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

  const SettingTile({super.key, required this.item});

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
    final iconColor = item.iconColor ?? context.iconDefault;
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: item.titleColor ?? context.textPrimary,
          ),
        ),
        if (item.subtitle != null)
          Text(
            item.subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.textSecondary),
          ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (item.hasCustomTrailing) {
      return item.trailing!;
    }

    if (item.isTappable) {
      return Icon(Icons.chevron_right, color: context.iconMuted, size: 22);
    }

    return const SizedBox.shrink();
  }
}

/// Quick access grid item
class QuickAccessTile extends StatelessWidget {
  final QuickAccessItem item;
  final VoidCallback onTap;

  const QuickAccessTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SettingsTheme.cardBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: SettingsTheme.cardDecoration(context),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: SettingsTheme.pagePadding,
      ),
      child: ResponsiveCardGrid(
        maxColumns: SettingsTheme.quickAccessColumns,
        spacing: SettingsTheme.quickAccessSpacing,
        children: [
          for (final item in items)
            QuickAccessTile(item: item, onTap: () => onItemTap(item.route)),
        ],
      ),
    );
  }
}

/// Profile header card with gradient background
class ProfileCard extends StatelessWidget {
  final String tier;
  final VoidCallback onEditTap;
  final String? photoUrl;
  final VoidCallback? onAvatarTap;

  const ProfileCard({
    super.key,
    required this.tier,
    required this.onEditTap,
    this.photoUrl,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(SettingsTheme.pagePadding),
      padding: const EdgeInsets.all(SettingsTheme.cardPadding),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(
          SettingsTheme.profileCardBorderRadius,
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(colors.onPrimary),
          const SizedBox(width: 16),
          Expanded(child: _buildInfo(colors.onPrimary)),
          _buildEditButton(context, colors.onPrimary),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color foreground) {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        width: SettingsTheme.iconContainerSize,
        height: SettingsTheme.iconContainerSize,
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(
            SettingsTheme.iconContainerRadius,
          ),
          image: photoUrl != null
              ? DecorationImage(
                  image: NetworkImage(photoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: photoUrl == null
            ? Icon(Icons.person, color: foreground, size: 28)
            : null,
      ),
    );
  }

  Widget _buildInfo(Color foreground) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Profile',
          style: TextStyle(
            color: foreground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tier.toUpperCase(),
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, Color foreground) {
    return GestureDetector(
      onTap: onEditTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.edit_outlined, color: foreground, size: 20),
      ),
    );
  }
}
