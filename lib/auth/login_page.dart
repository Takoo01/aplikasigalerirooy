import 'package:flutter/material.dart';
import 'package:galleryapp/coba.dart';
import 'package:provider/provider.dart';
import 'package:galleryapp/auth/auth_provider.dart' as local_auth;
import 'package:galleryapp/profil_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  bool isLoading = false;
  bool isLoginMode = true;

  void authenticate(BuildContext context) async {
    final authProvider = Provider.of<local_auth.AuthProvider>(context, listen: false);
    setState(() => isLoading = true);

    try {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email dan password tidak boleh kosong!")),
        );
        setState(() => isLoading = false);
        return;
      }

      String? errorMessage;
      if (isLoginMode) {
        errorMessage = await authProvider.login(
          emailController.text.trim(),
          passwordController.text.trim(),
          context,
        );
        if (errorMessage == null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
                (route) => false,
          );
        }
      } else {
        if (usernameController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Username tidak boleh kosong!")),
          );
          setState(() => isLoading = false);
          return;
        }
        errorMessage = await authProvider.register(
          emailController.text.trim(),
          passwordController.text.trim(),
          usernameController.text.trim(),
        );
        if (errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun Berhasil Dibuat. Silakan Login!')),
          );
          setState(() {
            isLoginMode = true;
            emailController.clear();
            passwordController.clear();
            usernameController.clear();
          });
        }
      }
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLoginMode ? "Login" : "Register",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      if (!isLoginMode)
                        TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: "Username",
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => authenticate(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isLoginMode ? "Login" : "Register",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => isLoginMode = !isLoginMode);
                        },
                        child: Text(
                          isLoginMode ? "Belum punya akun? Register" : "Sudah punya akun? Login",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
