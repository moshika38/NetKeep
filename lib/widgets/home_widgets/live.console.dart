import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class LiveConsoleWidget extends StatelessWidget {
  const LiveConsoleWidget({super.key});

  static const _logs = [
    ("[10:45:10]", " Initializing connection... OK"),
    ("[10:45:11]", " Handshake established."),
    ("[10:45:12]", " https://oneapp.hutch.lk -> 200 OK (38ms)"),
    ("[01:09:56]", " https://auth.hutch.lk -> 200 OK (23ms)"),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.28,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleBar(context),
          Divider(height: 1, color: AppColors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _logs.length; i++) ...[
                  _buildLogLine(_logs[i].$1, _logs[i].$2),
                  if (i < _logs.length - 1) const SizedBox(height: 6),
                ],
                const SizedBox(height: 6),
                _buildPromptLine(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _trafficLight(AppColors.tertiaryColor),
          const SizedBox(width: 6),
          _trafficLight(AppColors.primaryColor),
          const SizedBox(width: 6),
          _trafficLight(AppColors.secondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Live Console",
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(),
                SizedBox(width: 5),
                Text(
                  "LIVE",
                  style: TextStyle(
                    color: AppColors.secondaryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trafficLight(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLogLine(String time, String message) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: time,
            style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.4)),
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

  Widget _buildPromptLine() {
    return Row(
      children: [
        const Text(
          "> ",
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.secondaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const _BlinkingCursor(),
      ],
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

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
      opacity: Tween(begin: 0.0, end: 1.0).animate(_controller),
      child: Container(width: 7, height: 13, color: AppColors.secondaryColor),
    );
  }
}
