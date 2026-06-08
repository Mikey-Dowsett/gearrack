import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/gear.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/info_card.dart';

class GearPage extends StatelessWidget {
  final Gear gear;

  const GearPage({super.key, required this.gear});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final age = DateTime.now().year - gear.purchaseYear;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(gear.category.name, style: AppTextStyles.bodyLarge),
        backgroundColor: colors.background,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 200.h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment(-0.9, -0.9),
                        stops: [0.0, 0.5, 0.5, 1.0],
                        colors: [
                          colors.surfaceRaised,
                          colors.surfaceRaised,
                          colors.surfaceSunken,
                          colors.surfaceSunken,
                        ],
                        tileMode: TileMode.repeated,
                      ),
                    ),
                  ),
                  FaIcon(
                    gear.icon as FaIconData,
                    size: 75.sp,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoCard(
                    icon: FontAwesomeIcons.shop,
                    title: gear.brand,
                    value: gear.name,
                  ),
                  if (gear.isPack)
                    InfoCard(
                      icon: FontAwesomeIcons.boxOpen,
                      title: 'Capacity',
                      value: '${gear.capacity} L',
                    ),
                  Row(
                    children: [
                      Flexible(
                        child: InfoCard(
                          icon: FontAwesomeIcons.balanceScale,
                          title: 'Weight',
                          value: '${gear.weight} kg',
                        ),
                      ),
                      Flexible(
                        child: InfoCard(
                          icon: FontAwesomeIcons.tag,
                          title: 'Price',
                          value: '\$${gear.price} ',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: InfoCard(
                          icon: FontAwesomeIcons.box,
                          title: 'Quantity',
                          value: 'x${gear.quantity} ',
                        ),
                      ),
                      Flexible(
                        child: InfoCard(
                          icon: FontAwesomeIcons.clock,
                          title: 'Age',
                          value: '${age} yrs',
                        ),
                      ),
                    ],
                  ),
                  InfoCard(
                    icon: FontAwesomeIcons.certificate,
                    title: 'Condition',
                    value: gear.condition.name,
                  ),
                  InfoCard(
                    icon: FontAwesomeIcons.solidNoteSticky,
                    title: 'Notes',
                    value: gear.notes,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
