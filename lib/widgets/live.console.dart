import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';

class LiveConsoleWidget extends StatelessWidget {
  const LiveConsoleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Console Box Container
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Terminal Log Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildLogItem(
                      time: '[10:45:10]',
                      message: ' Initializing connection... OK',
                    ),
                    const SizedBox(height: 6),
                    _buildLogItem(
                      time: '[10:45:11]',
                      message: ' Handshake established.',
                    ),
                    const SizedBox(height: 6),
                    _buildLogItem(
                      time: '[10:45:12]',
                      message: ' https://oneapp.hutch.lk -> 200\nOK (38ms)',
                    ),
                    const SizedBox(height: 6),
                    _buildLogItem(
                      time: '[01:09:56]',
                      message: ' https://auth.hutch.lk -> 200 OK\n(23ms)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Single Log Line Helper
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
            style: TextStyle(color: AppColors.textColor.withOpacity(0.35)),
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
