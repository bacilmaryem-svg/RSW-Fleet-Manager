import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  // Maritime Color Palette
  final Color _primaryBlue = const Color(0xFF0A2342); // Deep Ocean
  final Color _accentTeal = const Color(0xFF2CA58D); // Sea Foam/Teal
  final Color _surfaceWhite = const Color(0xFFFFFFFF);
  final Color _textDark = const Color(0xFF1C1C1C);

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    
    // Simulate a slight delay for better UX feel if local
    if (name.isEmpty) {
       setState(() {
        _loading = false;
        _errorMessage = "Please enter your captain name.";
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('captains').get();
      debugPrint('LOGIN DEBUG - Trying login ...');

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
          _errorMessage = "Invalid credentials. Check your logbook.";
        });
      }
    } catch (e) {
      debugPrint('FIREBASE LOGIN ERROR: $e');
      setState(() {
        _errorMessage = "Connection lost. Check radio/internet.";
      });
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  String _extractName(Map<String, dynamic> data) {
    for (final key in ['name', 'Name', 'name ', 'captain', 'captain_name']) {
      if (data.containsKey(key)) {
        return (data[key] ?? '').toString().trim();
      }
    }
    for (final entry in data.entries) {
      if (entry.key.trim().toLowerCase().startsWith('name')) {
        return (entry.value ?? '').toString().trim();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image with Overlay
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1534951009808-766178b47a4f?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryBlue, const Color(0xFF0F3460)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
          ),
          // Dark overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // 2. Login Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceWhite.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentTeal.withOpacity(0.5), width: 2),
                    ),
                    child: Icon(Icons.sailing, size: 64, color: _surfaceWhite),
                  ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'RSW FLEET MANAGER',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _surfaceWhite,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Captain\'s Log Access',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: _surfaceWhite.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 48),

                  // Glassmorphic Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _surfaceWhite.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _surfaceWhite.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Captain Name',
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock,
                              isPassword: true,
                            ),
                            
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.lato(color: Colors.redAccent, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(),
                            ],

                            const SizedBox(height: 32),

                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  shadowColor: _accentTeal.withOpacity(0.5),
                                ).copyWith(
                                  elevation: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.pressed)) return 0;
                                      return 8;
                                  }),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'BOARD SHIP',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    '© 2025 RSW Marine Systems',
                    style: GoogleFonts.lato(
                      color: _surfaceWhite.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ).animate().fadeIn(delay: 1200.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.montserrat(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.lato(color: Colors.white, fontSize: 16),
            cursorColor: _accentTeal,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: isPassword ? '••••••••' : 'Enter $label',
              hintStyle: GoogleFonts.lato(color: Colors.white.withOpacity(0.2)),
            ),
          ),
        ),
      ],
    );
  }
}
