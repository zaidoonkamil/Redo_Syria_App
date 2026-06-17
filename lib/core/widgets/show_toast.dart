import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../styles/themes.dart';

void showSnackBarSuccess({
  required String text,
  required BuildContext context,
}) {
  showFancySnackBar(
    context: context,
    message: text,
    icon: Icons.check_circle_rounded,
    iconColor: primaryColor,
  );
}

void showSnackBarError({
  required String text,
  required BuildContext context,
}) {
  showFancySnackBar(
    context: context,
    message: text,
    icon: Icons.error_rounded,
    iconColor: Colors.redAccent,
  );
}

void showSnackBarInfo({
  required String text,
  required BuildContext context,
}) {
  showFancySnackBar(
    context: context,
    message: text,
    icon: Icons.info_rounded,
    iconColor: Colors.blueAccent,
  );
}


void showFancySnackBar({
  required BuildContext context,
  required String message,
  IconData icon = Icons.check_circle_rounded,
  Color iconColor = secondPrimaryColor,
  Color backgroundColor = const Color(0xFF111827),
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      elevation: 8,
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: iconColor.withOpacity(0.4),
        ),
      ),
      content: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.15),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
        ],
      ),
    ),
  );
}
