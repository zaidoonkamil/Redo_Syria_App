import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../styles/themes.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validate;
  final void Function()? onTap;
  final TextEditingController? controller;
  final int maxLines;

  const CustomTextField({
    super.key,
    this.controller,
    this.validate,
    required this.hintText,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0XFFF9FAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ,
          width: 1,
        ),
      ),
      child: TextFormField(
        textAlign:TextAlign.right,
        keyboardType: keyboardType,
        obscureText: obscureText,
        controller: controller,
        maxLines: maxLines,
        validator: validate,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Color(0XFF949D9E)
          ),
          border: InputBorder.none,
          prefixIcon: suffixIcon ,
        ),
      ),
    );
  }
}



class SearchTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const SearchTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.onTap,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late final TextEditingController _controller;
  bool hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();

    hasText = _controller.text.trim().isNotEmpty;

    _controller.addListener(() {
      final v = _controller.text.trim().isNotEmpty;
      if (v == hasText) return;
      if (!mounted) return;
      setState(() => hasText = v);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = hasText ? secondPrimaryColor : const Color(0XFF949D9E);
    final textColor = hasText ? secondPrimaryColor : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0XFFF9FAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextFormField(
        controller: _controller,
        readOnly: widget.readOnly,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        onTap: widget.onTap,
        onChanged: (v) {
          widget.onChanged?.call(v);
          print('change=============');
        },
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          height: 1.25,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0XFF949D9E),
          ),

          prefixIcon: Icon(
            Iconsax.search_normal,
            size: 16,
            color: iconColor,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 34,
          ),
        ),
      ),
    );
  }
}