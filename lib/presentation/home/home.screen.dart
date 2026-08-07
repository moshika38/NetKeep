import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.btns.dart';
import 'package:netkeep/widgets/app.card.dart';
import 'package:netkeep/widgets/home_widgets/app.header.dart';
import 'package:netkeep/widgets/home_widgets/home.app.bar.dart';
import 'package:netkeep/widgets/home_widgets/live.console.dart';
import 'package:netkeep/widgets/home_widgets/profile.dropdown.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int activeProfileIndex = 0;
  bool isKeepAliveRunning = false;

  void _toggleKeepAlive() {
    setState(() => isKeepAliveRunning = !isKeepAliveRunning);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar.homeAppBar(context, "NetKeep"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            const AppHeader(
              title: "NetKeep Status",
              subtitle: "Connection control center",
            ),
            const SizedBox(height: 12),
            _buildStatusCard(context),
            const SizedBox(height: 16),
            AppBtns(onTap: _toggleKeepAlive, isActive: isKeepAliveRunning),
            const SizedBox(height: 24),
            const AppHeader(
              title: "Keep-Alive Profiles",
              subtitle: "Select a power profile",
            ),
            const SizedBox(height: 12),
            ProfileDropdown(
              selectedIndex: activeProfileIndex,
              onChanged: (index) => setState(() => activeProfileIndex = index),
            ),
            const SizedBox(height: 24),
            const AppHeader(
              title: "Live Console",
              subtitle: "Real-time request logs",
            ),
            const SizedBox(height: 12),
            const LiveConsoleWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final running = isKeepAliveRunning;
    final accent = running ? AppColors.secondaryColor : AppColors.tertiaryColor;
    return AppCard(
      child: Row(
        children: [
          _PowerButton(active: running, onTap: _toggleKeepAlive),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  running ? "Connected" : "Disconnect",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  running ? "Keep-Alive is running" : "Relax Mode",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  running ? "Active" : "Idle",
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerButton extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;
  const _PowerButton({required this.active, required this.onTap});

  @override
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? AppColors.secondaryColor
        : AppColors.tertiaryColor;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final glow = widget.active ? 0.25 + (_controller.value * 0.4) : 0.3;
          return Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBgColor,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: glow),
                  blurRadius: 20 * (widget.active ? 1 + _controller.value : 1),
                ),
              ],
            ),
            child: Icon(Icons.power_settings_new, size: 34, color: color),
          );
        },
      ),
    );
  }
}
