import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingSpinner extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final Color? backgroundColor;
  final double opacity;

  const LottieLoadingSpinner({
    Key? key,
    this.message,
    this.color,
    this.size = 200.0,
    this.backgroundColor,
    this.opacity = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              'assets/loadingState.json',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: color ?? Colors.grey[300],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class LottieLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Color? backgroundColor;
  final double opacity;
  final double spinnerSize;
  final Color? textColor;

  const LottieLoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.backgroundColor = Colors.black,
    this.opacity = 0.5,
    this.spinnerSize = 200.0,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor?.withOpacity(opacity) ??
                Colors.black.withOpacity(opacity),
            child: LottieLoadingSpinner(
              message: loadingMessage,
              size: spinnerSize,
              color: textColor,
            ),
          ),
      ],
    );
  }
}
