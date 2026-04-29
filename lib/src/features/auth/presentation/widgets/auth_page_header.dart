import 'package:flutter/material.dart';

class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({
    required this.title,
    required this.subtitle,
    super.key,
    this.leading,
    this.titleStyle,
    this.subtitleStyle,
    this.subtitleMaxWidth = 480,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double subtitleMaxWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (leading != null) ...<Widget>[leading!, const SizedBox(height: 12)],
        Text(
          title,
          textAlign: TextAlign.center,
          style: titleStyle ?? theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: subtitleMaxWidth),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: subtitleStyle ?? theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
