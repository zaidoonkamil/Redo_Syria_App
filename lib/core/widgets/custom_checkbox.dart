import 'package:flutter/material.dart';

class CustomCheckBox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color activeColor;
  final Color borderColor;

  const CustomCheckBox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 18,
    this.activeColor = Colors.blue,
    this.borderColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value ? activeColor : borderColor,
            width: 1.5,
          ),
        ),
        child: value
            ? const Icon(
          Icons.check,
          size: 14,
          color: Colors.white,
        )
            : null,
      ),
    );
  }
}
