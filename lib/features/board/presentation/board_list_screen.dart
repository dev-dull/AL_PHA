import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BoardListScreen extends StatelessWidget {
  const BoardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlPHA'),
      ),
      body: const Center(
        child: Text('No boards yet. Create one to get started!'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('boardCreate'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
