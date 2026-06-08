import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/gear_card.dart';
import '../theme/app_colors.dart';
import '../models/gear.dart';
import '../models/category.dart';
import '../models/condition.dart';
import '../pages/add_gear.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final shelterfakeGear = Gear(
      'Big Agnes Copper Spur',
      'Big Agnes',
      Category.Shelter,
      false,
      0,
      1.73,
      350.0,
      2023,
      1,
      Condition.Good,
      'Lightweight 3-season tent. Says it fits 3 but it\'s more comfortable with only two people.',
      FontAwesomeIcons.tent,
    );

    final packGear = Gear(
      'Osprey Atmos AG 65L',
      'Osprey',
      Category.Backpack,
      true,
      65,
      2.24,
      299.95,
      2022,
      1,
      Condition.Worn,
      'Comfortable 65L pack with great weight distribution. Perfect for week-long backpacking trips. One of the straps is getting close to snapping. The front pocket zipper is also broken. I think there is also a hole somewhere because it\'s leaking water when it rains.',
      FontAwesomeIcons.suitcase,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GearCard(gear: shelterfakeGear),
            GearCard(gear: packGear),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGearPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
