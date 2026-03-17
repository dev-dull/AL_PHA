import 'package:flutter/material.dart';

class BoardDetailScreen extends StatelessWidget {
  final String boardId;

  const BoardDetailScreen({super.key, required this.boardId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Board $boardId'),
      ),
      body: const Center(
        child: Text('Board grid will render here.'),
      ),
    );
  }
}
