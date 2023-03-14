import 'package:flutter/material.dart';

class MainBtn extends StatelessWidget {
  final bool showProgress;
  final Color color;
  final String text;
  final Function() onPressed;

  const MainBtn(
      {Key? key,
      required this.showProgress,
      required this.color,
      required this.text,
      required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        elevation: 5.0,
        color: color,
        borderRadius: BorderRadius.circular(30.0),
        child: MaterialButton(
          onPressed: showProgress ? null : onPressed,
          child: showProgress
              ? const Center(child: CircularProgressIndicator(color: Colors.white,))
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
