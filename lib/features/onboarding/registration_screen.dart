import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/routes.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go(Routes.discover),
          child: const Text('Finish → Discover'),
        ),
      ),
    );
  }
}
