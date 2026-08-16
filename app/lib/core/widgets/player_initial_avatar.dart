import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:la_pocha/core/utils/player_colors.dart';

class PlayerInitialAvatar extends StatelessWidget {
  const PlayerInitialAvatar({
    super.key,
    required this.name,
    required this.colorIndex,
    this.photoUrl,
    this.radius = 20,
  });

  final String name;
  final int colorIndex;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: playerAvatarColorForIndex(colorIndex),
        backgroundImage: CachedNetworkImageProvider(url),
      );
    }

    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: playerAvatarColorForIndex(colorIndex),
      foregroundColor: Colors.white,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
