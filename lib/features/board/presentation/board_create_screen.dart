import 'package:flutter/material.dart';

class BoardCreateScreen extends StatelessWidget {
  const BoardCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Board'),
      ),
      body: const Center(
        child: Text('Template picker will render here.'),
      ),
    );
  }
}
