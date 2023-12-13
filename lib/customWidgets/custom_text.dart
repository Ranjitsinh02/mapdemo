import 'package:flutter/material.dart';

class CustomTextWidget extends StatelessWidget {
  const CustomTextWidget({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Theme.of(context).textTheme.caption?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          fontFamily: "Poppins Medium",
          color: Colors.black,
        ),
      ),
    );
  }
}