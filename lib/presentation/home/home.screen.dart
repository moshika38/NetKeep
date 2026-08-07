import 'package:flutter/material.dart';
import 'package:netkeep/utils/theme.dart';
import 'package:netkeep/widgets/app.btns.dart';
import 'package:netkeep/widgets/app.card.dart';
import 'package:netkeep/widgets/app.header.dart';
import 'package:netkeep/widgets/home.app.bar.dart';
import 'package:netkeep/widgets/live.console.dart';
import 'package:netkeep/widgets/profile.cards.dart';
import 'package:netkeep/widgets/speed.banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int activeProfileIndex=0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar.homeAppBar(context, "Home Screen"),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              AppHeader(title: "Current Network Speed"),
              const SizedBox(height: 16),

              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SpeedBanner(
                          speed: "15.5",
                          icon: Icons.arrow_downward,
                          color: AppColors.secondaryColor,
                        ),
                        const SizedBox(height: 10),
                        SpeedBanner(
                          speed: "15.5",
                          icon: Icons.arrow_upward,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.backgroundColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.speed, size: 35, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              AppHeader(title: "NetKeep Status"),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.tertiaryColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          size: 80,
                          Icons.power,
                          color: AppColors.tertiaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Disconnect",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: AppColors.tertiaryColor,
                      ),
                    ),
                    Text(
                      "Relex Mode",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              AppBtns(onTap: () {}),

              const SizedBox(height: 16),
              AppHeader(title: "Keep-Alive Profiles"),
              const SizedBox(height: 16),

              ProfileCards(
                isActive: activeProfileIndex==0,
                icon: Icons.sync,
                title: "Normal Model",
                subTitle: "Interval 5s",
              ),
              ProfileCards(
                isActive: activeProfileIndex==1,
                icon: Icons.battery_charging_full,
                title: "Saver Model",
                subTitle: "Interval 5s",
              ),
              ProfileCards(
                isActive: activeProfileIndex==2,
                icon: Icons.sports_esports,
                title: "Game Model",
                subTitle: "Interval 5s",
              ),
              const SizedBox(height: 16),
              AppHeader(title: "Live Console"),
              const SizedBox(height: 16),

              LiveConsoleWidget()
              
            ],
          ),
        ),
      ),
    );
  }
}
