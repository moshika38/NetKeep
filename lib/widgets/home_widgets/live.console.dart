import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class LiveConsoleWidget extends StatelessWidget {
  const LiveConsoleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConsoleHeader(context),
          Divider(height: 1, color: AppColors.white.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogItem(
                  time: '[10:45:10]',
                  message: ' Initializing connection... OK',
                ),
                const SizedBox(height: 8),
                _buildLogItem(
                  time: '[10:45:11]',
                  message: ' Handshake established.',
                ),
                const SizedBox(height: 8),
                _buildLogItem(
                  time: '[10:45:12]',
                  message: ' https://oneapp.hutch.lk -> 200\nOK (38ms)',
                ),
                const SizedBox(height: 8),
                _buildLogItem(
                  time: '[01:09:56]',
                  message: ' https://auth.hutch.lk -> 200 OK\n(23ms)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _dot(color: AppColors.tertiaryColor),
          const SizedBox(width: 5),
          _dot(color: AppColors.primaryColor),
          const SizedBox(width: 5),
          _dot(color: AppColors.secondaryColor),
          const SizedBox(width: 12),
          Text(
            "Live Console",
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(),
                SizedBox(width: 6),
                Text(
                  "LIVE",
                  style: TextStyle(
                    color: AppColors.secondaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({required Color color}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
      ),
    );
  }

  Widget _buildLogItem({required String time, required String message}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: time,
            style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.35)),
          ),
          TextSpan(
            text: message,
            style: const TextStyle(
              color: AppColors.textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.2, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryColor.withValues(alpha: 0.7),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}
