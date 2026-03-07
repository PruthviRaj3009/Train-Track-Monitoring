import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Registration screen.
///
/// Creates a new user account using Firebase Authentication.
class SignupPage extends StatelessWidget {
  SignupPage({super.key});

  // Controllers
  /// Captures the user's display name (not currently persisted).
  final TextEditingController nameController = TextEditingController();

  /// Captures the email address used for Firebase Auth.
  final TextEditingController emailController = TextEditingController();

  /// Captures the password for account creation.
  final TextEditingController passwordController = TextEditingController();

  /// Captures the password confirmation to prevent typos.
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Firebase Signup Function
  /// Creates a Firebase user account after validating password confirmation.
  ///
  /// On success, displays a confirmation message and returns to the previous
  /// screen (login).
  Future<void> signupUser(BuildContext context) async {
    // Local validation to avoid an unnecessary network request.
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
        ),
      );
      return;
    }

    try {
      // Firebase API call: creates a new account using email/password.
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully"),
        ),
      );

      // Go back to Login Page after successful signup
      Navigator.pop(context);
    } catch (e) {
      // Surfaces the exception message for troubleshooting (e.g. weak password).
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget structure:
    // - Decorative/animated header
    // - Input form
    // - Create account action
    // - Navigation back to login
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // TOP DESIGN
            Container(
              height: 350,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Center(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 1500),
                    child: _inputContainer(
                      children: [
                        _inputField(
                          "Full Name",
                          controller: nameController,
                        ),
                        _inputField(
                          "Email",
                          controller: emailController,
                        ),
                        _inputField(
                          "Password",
                          isPassword: true,
                          controller: passwordController,
                        ),
                        _inputField(
                          "Confirm Password",
                          isPassword: true,
                          controller: confirmPasswordController,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // CREATE ACCOUNT BUTTON
                  FadeInUp(
                    duration: const Duration(milliseconds: 1700),
                    child: GestureDetector(
                      // Triggers the Firebase account creation flow.
                      onTap: () {
                        signupUser(context);
                      },
                      child: _gradientButton("Create Account"),
                    ),
                  ),

                  const SizedBox(height: 30),

                  FadeInUp(
                    duration: const Duration(milliseconds: 1800),
                    child: GestureDetector(
                      // Returns to the previous route (login).
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(
                          color: Color.fromRGBO(143, 148, 251, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// REUSED STYLE
  ///
  /// Wraps related input fields with consistent padding and border styling.
  Widget _inputContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromRGBO(143, 148, 251, 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(143, 148, 251, .2),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  /// Builds a single styled text input.
  ///
  /// When [isPassword] is true, the text is obscured.
  Widget _inputField(
    String hint, {
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(143, 148, 251, 1),
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }

  /// Builds the primary call-to-action button with the app's gradient style.
  Widget _gradientButton(String text) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(143, 148, 251, 1),
            Color.fromRGBO(143, 148, 251, .6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
