import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/design_system/components/brand/app_logo.dart';

export 'app/app.dart';

void main() {
  runApp(const IAgreeApp());
}

/// Basit açılış ekranı (testlerde kök ekran olarak kullanılır).
class IAgreePlaceholder extends StatelessWidget {
  const IAgreePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AppLogo.auto(wordmark: true)));
  }
}
