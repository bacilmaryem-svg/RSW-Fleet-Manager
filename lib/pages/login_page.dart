import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  final ValueChanged<String> onLogin;

  const LoginPage({
    super.key,
    required this.onLogin,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Capitan');
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final snapshot = await FirebaseFirestore.instance.collection('captains').get();
    debugPrint('TEST DOCS => ${snapshot.docs.map((d) => d.data())}');
    debugPrint('LOGIN DEBUG - Trying login ...');
    debugPrint('Name entered: $name');
    debugPrint('Password entered: $password');

    try {
      debugPrint('Firebase returned: ${snapshot.docs.length} documents');

      Map<String, dynamic>? matching;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final storedName = _extractName(data).toLowerCase();
        final storedPass = (data['password'] ?? '').toString().trim();
        if (storedName == name.toLowerCase() && storedPass == password) {
          matching = data;
          break;
        }
      }

      if (matching != null) {
        debugPrint('SUCCESS - Login OK for captain $name');
        widget.onLogin(name);
      } else {
        debugPrint('ERROR - No user found with this name/password');
        setState(() {
          _errorMessage = "Invalid name or password.";
        });
      }
    } catch (e) {
      debugPrint('FIREBASE LOGIN ERROR: $e');
      setState(() {
        _errorMessage = "Connection error: $e";
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8), Color(0xFFF5FBFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                        child: const Icon(Icons.water, color: Color(0xFF0EA5E9), size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Fish Tank Operations',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Secure access for captains to manage RSW tanks, species sampling, and cisterns.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey[600]),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Captain's name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _handleLogin,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Enter the Fleet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractName(Map<String, dynamic> data) {
    for (final key in ['name', 'Name', 'name ', 'captain', 'captain_name']) {
      if (data.containsKey(key)) {
        return (data[key] ?? '').toString().trim();
      }
    }
    // Fallback: find the first key that resembles "name"
    for (final entry in data.entries) {
      if (entry.key.trim().toLowerCase().startsWith('name')) {
        return (entry.value ?? '').toString().trim();
      }
    }
    return '';
  }
}
