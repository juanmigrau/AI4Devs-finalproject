import 'package:flutter/material.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/favorites/domain/entities/favorite_player.dart';

class FavoritesChipSection extends StatelessWidget {
  const FavoritesChipSection({
    super.key,
    required this.visibleFavorites,
    this.currentUser,
    this.onFavoriteTap,
  });

  final List<FavoritePlayer> visibleFavorites;
  final UserProfile? currentUser;
  final ValueChanged<FavoritePlayer>? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final user = currentUser;
    final hasChips = user != null || visibleFavorites.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAVORITOS',
          style: textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        if (!hasChips)
          Text(
            'Añade jugadores frecuentes con ⭐',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user != null)
                FilterChip(
                  key: const Key('currentUserFavoriteChip'),
                  avatar: Icon(
                    Icons.account_circle,
                    color: colors.primary,
                    size: 18,
                  ),
                  label: Text(
                    user.displayName,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: colors.primaryContainer,
                  showCheckmark: false,
                  onSelected: (_) => onFavoriteTap?.call(
                    FavoritePlayer(
                      id: user.uid,
                      displayName: user.displayName,
                      userId: user.uid,
                      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                    ),
                  ),
                ),
              ...visibleFavorites.map(
                (favorite) => FilterChip(
                  label: Text(favorite.displayName),
                  onSelected: (_) => onFavoriteTap?.call(favorite),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
