import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogo;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLogo = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          if (showLogo)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                'assets/images/app_logo.png', // Your logo path
                height: 32, // Adjust based on your logo
                fit: BoxFit.contain,
              ),
            ),
          Text(title),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      actions: actions,
    );
  }
}