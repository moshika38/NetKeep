import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class LiveConsoleWidget extends StatelessWidget {
  final List<(String, String)> _logs;
  final String vpnStage;
  final int? vpnLatencyMs;

  const LiveConsoleWidget({
    super.key,
    required this._logs,
    this.vpnStage = 'disconnected',
    this.vpnLatencyMs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.28,
      decoration: BoxDecoration(
        color: AppColors.cardAltColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleBar(context),
          Divider(height: 1, color: AppColors.white.withValues(alpha: 0.08)),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),

              itemCount: _logs.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildPromptLine();
                }

                final reversedIndex = _logs.length - index;
                final log = _logs[reversedIndex];

                return _buildLogLine(log.$1, log.$2);
              },
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
          const SizedBox(width: 5),
          _trafficLight(AppColors.primaryColor),
          const SizedBox(width: 5),
          _trafficLight(AppColors.secondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "LIVE CONSOLE",
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.zero,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                if (vpnLatencyMs != null) ...[
                  const SizedBox(width: 6),
                  Container(width: 1, height: 9, color: _statusColor.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text(
                    '${vpnLatencyMs}ms',
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (vpnStage) {
      case 'connected':
        return AppColors.secondaryColor;
      case 'connecting':
        return AppColors.primaryColor;
      default:
        return AppColors.tertiaryColor;
    }
  }

  String get _statusLabel {
    switch (vpnStage) {
      case 'connected':
        return 'CONNECTED';
      case 'connecting':
        return 'CONNECTING';
      default:
        return 'DISCONNECTED';
    }
  }

  Widget _trafficLight(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
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
            style: TextStyle(
              color: _resolveMessageColor(message),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveMessageColor(String message) {
    final statusMatch = RegExp(r'Status:\s*(\d{3}|[A-Za-z]+)').firstMatch(message);
    final status = statusMatch?.group(1) ?? '';

    if (status.toLowerCase() == 'timeout' || status.toLowerCase() == 'error') {
      return AppColors.tertiaryColor;
    }

    final code = int.tryParse(status);
    if (code != null && code >= 400 && code < 500) {
      return Colors.orangeAccent.withValues(alpha: 0.9);
    }

    return AppColors.textColor;
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
