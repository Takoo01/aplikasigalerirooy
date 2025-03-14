// import 'package:flutter/material.dart';
// import 'package:galleryapp/auth/auth_provider.dart';
// import 'package:provider/provider.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   TextEditingController email = TextEditingController();
//   TextEditingController password = TextEditingController();
//   TextEditingController username = TextEditingController();
//   bool _isLogin = true; // Default tampilan adalah Login
//
//   @override
//   Widget build(BuildContext context) {
//     var authProvider = Provider.of<AuthProvider>(context);
//
//     return Container(
//       color: const Color.fromARGB(255, 29, 29, 29),
//       child: SafeArea(
//         child: Scaffold(
//           resizeToAvoidBottomInset: false,
//           body: Stack(
//             children: [
//               Container(
//                 height: MediaQuery.of(context).size.height,
//                 width: MediaQuery.of(context).size.width,
//                 decoration: const BoxDecoration(
//                   image: DecorationImage(
//                     image: AssetImage("images/dark_pattern.jpg"),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               Column(
//                 children: [
//                   Container(
//                     height: MediaQuery.of(context).size.height / 4 - 20,
//                     decoration: const BoxDecoration(
//                       color: Color.fromARGB(255, 29, 29, 29),
//                       borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.green,
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                           offset: Offset(0, 5),
//                         )
//                       ],
//                     ),
//                   ),
//                   const Spacer(),
//                   Container(
//                     height: MediaQuery.of(context).size.height / 4 - 20,
//                     decoration: const BoxDecoration(
//                       color: Color.fromARGB(255, 29, 29, 29),
//                       borderRadius: BorderRadius.only(topRight: Radius.circular(50)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.green,
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                           offset: Offset(0, -5),
//                         )
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               Container(
//                 margin: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _isLogin ? "Login" : "Register",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: Theme.of(context).textTheme.headlineLarge?.fontSize,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context).canvasColor,
//                         borderRadius: BorderRadius.circular(20),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: Colors.green,
//                             spreadRadius: 1,
//                             blurRadius: 2,
//                             offset: Offset(0, 3),
//                           )
//                         ],
//                       ),
//                       child: Form(
//                         child: Column(
//                           children: [
//                             if (!_isLogin)
//                               TextFormField(
//                                 controller: username,
//                                 decoration: const InputDecoration(
//                                   labelText: "Username",
//                                   border: OutlineInputBorder(),
//                                 ),
//                               ),
//                             const SizedBox(height: 15),
//                             TextFormField(
//                               controller: email,
//                               decoration: const InputDecoration(
//                                 labelText: "Email",
//                                 border: OutlineInputBorder(),
//                               ),
//                               keyboardType: TextInputType.emailAddress,
//                             ),
//                             const SizedBox(height: 15),
//                             TextFormField(
//                               controller: password,
//                               decoration: const InputDecoration(
//                                 labelText: "Password",
//                                 border: OutlineInputBorder(),
//                               ),
//                               obscureText: true,
//                             ),
//                             const SizedBox(height: 30),
//                             SizedBox(
//                               width: MediaQuery.of(context).size.width,
//                               child: ElevatedButton(
//                                 onPressed: () async {
//                                   String? error;
//                                   if (_isLogin) {
//                                     error = await authProvider.login(email.text, password.text);
//                                   } else {
//                                     // Pass the username as an argument when registering
//                                     error = await authProvider.register(email.text, password.text, username.text);
//                                   }
//                                   if (error != null) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(content: Text(error)),
//                                     );
//                                   }
//                                 },
//                                 child: Text(_isLogin ? "Login" : "Register"),
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             TextButton(
//                               onPressed: () {
//                                 setState(() {
//                                   _isLogin = !_isLogin;
//                                 });
//                               },
//                               child: Text(_isLogin ? "Create account" : "I already have an account"),
//                             )
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
