import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SecurityBlockApp extends StatelessWidget {
  const SecurityBlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.shield_rounded,
                    size: 88,
                    color: AppColors.dangerColor,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Guvenlik Ihlali Tespit Edildi: Cihazinizda root veya jailbreak islemi tespit edilmistir. Finansal verilerinizin guvenligi icin CariFlow bu cihazda calistirilamaz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
