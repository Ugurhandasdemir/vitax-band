import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Alt ekranlar için ortak iskelet: geri oku, ortalı başlık, isteğe bağlı aksiyon.
class VDetailScaffold extends StatelessWidget {
  const VDetailScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottom,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final Widget? bottom;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: VColors.background,
    appBar: AppBar(
      backgroundColor: VColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        key: const ValueKey('detail-back'),
        icon: const Icon(Icons.arrow_back, color: VColors.onSurface),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(title, style: VText.headlineMd),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: VColors.surfaceContainerHighest),
      ),
    ),
    body: body,
    bottomNavigationBar: bottom,
  );
}
