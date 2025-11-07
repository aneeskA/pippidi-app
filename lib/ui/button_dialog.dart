import 'package:flutter/material.dart';

class DialogButton extends StatelessWidget {
  final String name;
  final VoidCallback callback;
  const DialogButton({
    super.key,
    required this.name,
    required this.callback,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      elevation: 0,
      onPressed: callback,
      child: Text(name),
      color: Colors.deepPurple.shade900,
      textColor: Colors.white,
    );
  }
}
