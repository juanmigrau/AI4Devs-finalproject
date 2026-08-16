import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';

class UserSearchField extends StatefulWidget {
  const UserSearchField({
    super.key,
    required this.onQueryChanged,
    required this.onClosed,
  });

  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClosed;

  @override
  State<UserSearchField> createState() => _UserSearchFieldState();
}

class _UserSearchFieldState extends State<UserSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.white,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: 'Buscar usuario…',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        border: InputBorder.none,
        suffixIcon: IconButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              _controller.clear();
              widget.onQueryChanged('');
            } else {
              widget.onClosed();
            }
          },
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ),
      onChanged: widget.onQueryChanged,
    );
  }
}

/// App bar replacement while user search is active.
class UserSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UserSearchAppBar({
    super.key,
    required this.onQueryChanged,
    required this.onClosed,
  });

  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClosed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              IconButton(
                onPressed: onClosed,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: UserSearchField(
                  onQueryChanged: onQueryChanged,
                  onClosed: onClosed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
