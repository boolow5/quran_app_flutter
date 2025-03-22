import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:MeezanSync/constants.dart';
import 'package:MeezanSync/providers/quran_data_provider.dart';
import 'package:MeezanSync/providers/theme_provider.dart';
import 'package:MeezanSync/services/auth.dart';
import 'package:MeezanSync/utils/utils.dart';

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
  bool _emailLogin = false;
  bool _showPassword = false;

  bool _googleLoginLoading = false;
  bool _facebookLoginLoading = false;
  bool _emailLoginLoading = false;

  @override
  void initState() {
    super.initState();
    updateThemeScale(context);
  }

  void _signIn() async {
    try {
      setState(() {
        _errorMessage = null;
        _emailLoginLoading = true;
      });
      final fun = _isLogin
          ? () => AuthService().signInWithEmailAndPassword(
              _emailController.text, _passwordController.text)
          : () => AuthService().registerUserWithEmailAndPassword(
              _emailController.text, _passwordController.text);

      print("[${_isLogin ? 'Login' : 'Register'}] Signing in...");
      await fun();
      print("[${_isLogin ? 'Login' : 'Register'}] Signed in");

      bool success = context.mounted || navigatorKey.currentContext != null;
      if (!success) {
        Future.microtask(() {
          showMessage(
            "Successfully signed in with email",
            type: AlertMessageType.success,
          );
        });
      } else {
        Future.microtask(() {
          showMessage(
            "Successfully signed in with email",
            type: AlertMessageType.success,
          );
        });
      }
      if (context.mounted) {
        context.go('/');
      } else if (navigatorKey.currentContext != null) {
        navigatorKey.currentContext?.go('/');
      }
    } catch (e) {
      final isInvalidCredentials =
          e.toString().contains("Invalid email or password");
      if (isInvalidCredentials) {
        setState(() {
          _errorMessage = "Invalid email or password";
        });
        Future.microtask(() {
          showMessage(
            "Invalid email or password",
            type: AlertMessageType.fail,
          );
        });
      }
      final message = e.toString().split("]").last.trim();
      print("[${_isLogin ? 'Login' : 'Register'}] Error logging in: $e");
      print("[${_isLogin ? 'Login' : 'Register'}] Error message: $message");
      setState(() {
        _errorMessage = message;
      });
      Future.microtask(() {
        showMessage(
          "Failed to login. We are working on it",
          type: AlertMessageType.fail,
        );
      });
    } finally {
      setState(() {
        _emailLoginLoading = false;
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
                      if (_emailLogin) ...[
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
                          child: Center(
                            child: Text(!_isLogin
                                ? _emailLoginLoading
                                    ? "Signing up..."
                                    : "Sign up"
                                : _emailLoginLoading
                                    ? "Signing in..."
                                    : "Sign in"),
                          ),
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
                        const SizedBox(height: 200),
                      ] else ...[
                        // or login with google
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            setState(() {
                              _emailLogin = true;
                            });
                          },
                          child: SizedBox(
                            width: 200,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 16,
                                ),
                                SizedBox(
                                  width: 180,
                                  child: Center(
                                    child: const Text('Use email and password'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),
                      ],

                      // or login with google
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // line separator
                          SizedBox(
                            width: 60,
                            child: Divider(
                              thickness: 1,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Text('or'),
                          const SizedBox(
                            width: 16,
                          ),
                          // line separator
                          SizedBox(
                            width: 60,
                            child: Divider(
                              thickness: 1,
                              color: Colors.grey,
                            ),
                          ),
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
                          try {
                            setState(() {
                              _googleLoginLoading = true;
                            });

                            final user = await AuthService().signInWithGoogle();

                            if (user == null) {
                              print("User is null");
                              throw "User is null";
                            }

                            print("Login successful: $user");

                            // Show success message after sign-in
                            Future.microtask(() {
                              showMessage(
                                "Successfully signed in with Google",
                                type: AlertMessageType.success,
                              );
                            });

                            // Navigate only if context is still valid
                            if (context.mounted) {
                              context.go('/');
                            } else if (navigatorKey.currentContext != null) {
                              navigatorKey.currentContext?.go('/');
                            }
                          } catch (err) {
                            print("Error signing in with Google: $err");

                            // Show error message with a microtask to ensure UI is ready
                            Future.microtask(() {
                              showMessage(
                                "Google sign in failed!",
                                type: AlertMessageType.fail,
                              );
                            });
                          } finally {
                            setState(() {
                              _googleLoginLoading = false;
                            });
                          }
                        },
                        child: SizedBox(
                          width: 200,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // if loading show loading spinner
                              _googleLoginLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      'assets/images/google-logo.svg',
                                      height: 16,
                                    ),
                              SizedBox(
                                width: 180,
                                child: Center(
                                  child: Text(
                                    'Sign ${_isLogin ? "in" : "up"} with Google',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),
                      // test showMessage button
                      // ElevatedButton(
                      //   onPressed: () {
                      //     showMessage(
                      //       "Test message",
                      //       type: AlertMessageType.fail,
                      //     );
                      //   },
                      //   child: const Text('Show message'),
                      // ),
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
    final isPassword = label.toLowerCase() == 'password';
    final input = TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: isPassword && !_showPassword,
      onChanged: (value) {
        // print("[$label][$isPassword ? 'password' : 'email'] changed: $value");
      },
      onSubmitted: (value) {
        if (isPassword && controller.text.isNotEmpty) {
          _signIn();
        }
      },
    );
    return isPassword
        ? Stack(
            children: [
              input,
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
            ],
          )
        : input;
  }
}
