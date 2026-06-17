import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../ navigation/navigation.dart';
import '../styles/themes.dart';
import 'constant.dart';

import 'package:flutter/material.dart';


class CustomAppBarBack extends StatelessWidget {
  const CustomAppBarBack({
    super.key,
    this.title = 'ريــــــدو',
    this.isLoading = false,
  });

  final String title;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: adminOrUser =='driver'? primaryColor:secondPrimaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),

        border: Border(
          bottom: BorderSide(
            color:adminOrUser =='driver'? secondPrimaryColor.withOpacity(0.15):primaryColor.withOpacity(0.15),
            width: 0.6,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
            InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}
