import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:la_pocha/core/utils/player_colors.dart';

class PlayerInitialAvatar extends StatelessWidget {
  const PlayerInitialAvatar({
    super.key,
    required this.name,
    required this.colorIndex,
    this.photoURL,
    this.radius = 20,
  });

  final String name;
  final int colorIndex;
  final String? photoURL;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = photoURL;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: radius * 2,
        height: radius * 2,
        imageBuilder: (context, imageProvider) =>
            CircleAvatar(radius: radius, backgroundImage: imageProvider),
        placeholder: (context, url) =>
            _InitialsAvatar(name: name, colorIndex: colorIndex, radius: radius),
        errorWidget: (context, url, error) =>
            _InitialsAvatar(name: name, colorIndex: colorIndex, radius: radius),
      );
    }

    return _InitialsAvatar(name: name, colorIndex: colorIndex, radius: radius);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.name,
    required this.colorIndex,
    required this.radius,
  });

  final String name;
  final int colorIndex;
  final double radius;

  @override
  Widget build(BuildContext context) {
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
