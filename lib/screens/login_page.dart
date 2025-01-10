import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:quran_app_flutter/providers/quran_data_provider.dart';
import 'package:quran_app_flutter/providers/theme_provider.dart';
import 'package:quran_app_flutter/services/auth.dart';
import 'package:quran_app_flutter/utils/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    updateThemeScale(context);
  }

  void _signIn() async {
    try {
      final fun = _isLogin
          ? () => AuthService().signInWithEmailAndPassword(
              _emailController.text, _passwordController.text)
          : () => AuthService().registerUserWithEmailAndPassword(
              _emailController.text, _passwordController.text);
      await fun().then((value) {
        context.go('/');
      });
    } catch (e) {
      final message = e.toString().split("]").last.trim();
      print("Error logging in: $e");
      setState(() {
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(!_isLogin ? 'Register' : 'Login'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: StreamBuilder(
          stream: AuthService().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            return LayoutBuilder(builder: (context, constraints) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      _buildInputField('Email', _emailController),
                      _buildInputField('Password', _passwordController),
                      const SizedBox(
                        height: 16,
                      ),
                      ElevatedButton(
                        onPressed: _signIn,
                        child: Text(!_isLogin ? "Sign up" : "Sign in"),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isLogin
                              ? "Don't have an account?"
                              : "Already have an account?"),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(_isLogin ? "Sign up" : "Sign in"),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      // or login with google
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          await AuthService().signInWithGoogle();
                          context.go('/');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              'assets/images/google-logo.svg',
                              height: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text('Sign in with Google'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      onSubmitted: (value) {
        if (label == 'Password' && controller.text.isNotEmpty) {
          _signIn();
        }
      },
    );
  }
}
