import 'package:flutter/material.dart';

import '../../../../shared/widgets/shimmer_box.dart';

class AuthBootPage extends StatelessWidget {
  const AuthBootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ShimmerCentered(),
      ),
    );
  }
}
