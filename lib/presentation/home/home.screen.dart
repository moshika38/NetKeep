import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.btns.dart';
import 'package:netkeep/widgets/app.card.dart';
import 'package:netkeep/widgets/home_widgets/app.header.dart';
import 'package:netkeep/widgets/home_widgets/home.app.bar.dart';
import 'package:netkeep/widgets/home_widgets/live.console.dart';
import 'package:netkeep/widgets/home_widgets/profile.cards.dart';
import 'package:netkeep/widgets/speed.banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int activeProfileIndex = 0;
  bool isKeepAliveRunning = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

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
            _buildGreetingHeader(context),
            const SizedBox(height: 18),
            _buildSpeedHeroCard(context),
            const SizedBox(height: 22),
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
            const SizedBox(height: 14),
            ProfileCards(
              isActive: activeProfileIndex == 0,
              icon: Icons.sync,
              title: "Normal Model",
              subTitle: "Interval 5s · Balanced",
              onTap: () => setState(() => activeProfileIndex = 0),
            ),
            ProfileCards(
              isActive: activeProfileIndex == 1,
              icon: Icons.battery_charging_full,
              title: "Saver Model",
              subTitle: "Interval 10s · Power saving",
              onTap: () => setState(() => activeProfileIndex = 1),
            ),
            ProfileCards(
              isActive: activeProfileIndex == 2,
              icon: Icons.sports_esports,
              title: "Game Model",
              subTitle: "Interval 2s · Low latency",
              onTap: () => setState(() => activeProfileIndex = 2),
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

  Widget _buildGreetingHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Keep your connection alive",
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                _todayLabel,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _todayLabel {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    final now = DateTime.now();
    return "${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  Widget _buildSpeedHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF23221F), Color(0xFF2E2413)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withOpacity(0.14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _PulseDot(),
                          const SizedBox(width: 8),
                          Text(
                            "Live Network Speed",
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: AppColors.white.withOpacity(0.75),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Icon(
                            Icons.arrow_downward,
                            size: 22,
                            color: AppColors.secondaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "15.5",
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              "Mbps",
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: AppColors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SpeedBanner(
                        speed: "1.2",
                        icon: Icons.arrow_upward,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
                _buildSpeedRing(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedRing(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: CircularProgressIndicator(
              value: 0.68,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.white.withOpacity(0.08),
              color: AppColors.primaryColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.speed,
                size: 22,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 2),
              Text(
                "68%",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
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
              color: accent.withOpacity(0.12),
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
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryColor.withOpacity(0.7),
              blurRadius: 6,
            ),
          ],
        ),
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
                  color: color.withOpacity(glow),
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
