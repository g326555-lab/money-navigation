import 'package:flutter/widgets.dart';

import '../core/spacing.dart';

/// The brand hero object (DESIGN.md "Coin"): a 3D Thai-style bimetal coin,
/// silver outer ring and gold center with the baht sign. One per screen at
/// most. The image already carries its own soft contact shadow.
class Coin extends StatelessWidget {
  const Coin({super.key, this.size = AppSizes.heroCoin});

  static const asset = 'assets/images/coin.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}
