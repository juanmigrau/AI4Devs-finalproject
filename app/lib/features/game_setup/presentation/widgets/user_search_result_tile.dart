import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/game_setup/domain/entities/user_search_result.dart';
import 'package:la_pocha/features/game_setup/domain/utils/user_search_helper.dart';

class UserSearchResultTile extends StatelessWidget {
  const UserSearchResultTile({
    super.key,
    required this.user,
    required this.colorIndex,
    required this.alreadyInGame,
    required this.onSelected,
  });

  final UserSearchResult user;
  final int colorIndex;
  final bool alreadyInGame;
  final ValueChanged<UserSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final obfuscated = UserSearchHelper.obfuscateEmail(user.email);

    return ListTile(
      leading: PlayerInitialAvatar(
        name: user.displayName,
        colorIndex: colorIndex,
        photoURL: user.photoUrl,
      ),
      title: Text(
        user.displayName,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        obfuscated,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: alreadyInGame
          ? Chip(
              avatar: Icon(
                Icons.check,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              label: const Text('Añadido'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      onTap: alreadyInGame ? null : () => onSelected(user),
    );
  }
}
