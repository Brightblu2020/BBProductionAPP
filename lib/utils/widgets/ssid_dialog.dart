import 'package:flutter/material.dart';
import 'package:bb_factory_test_app/controller/controller.dart';

class SSIDDialog extends StatefulWidget {
  const SSIDDialog({super.key});

  @override
  State<SSIDDialog> createState() => _SSIDDialogState();
}

class _SSIDDialogState extends State<SSIDDialog> {
   final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
Controller _controller = Controller();
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Login'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: () {
            String username = _usernameController.text;
            String password = _passwordController.text;

            if (username.isNotEmpty && password.isNotEmpty) {
              // Handle form submission logic here
              // print('Username: $username');
              // print('Password: $password');
              _controller.configureWifi(username: username, password: password);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill all fields'),
                ),
              );
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}