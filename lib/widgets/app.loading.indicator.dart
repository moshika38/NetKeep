import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Reusable generic loading indicator component using the NetKeep Lottie animation asset.
class AppLoadingIndicator extends StatelessWidget {
  final double? size;
  final BoxFit fit;

  const AppLoadingIndicator({
    super.key,
    this.size = 100.0,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/lotte/loading.json',
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('AppLoadingIndicator: Error loading Lottie asset: $error');
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
