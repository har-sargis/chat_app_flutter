import 'dart:io';

import 'package:chat_app/widgets/image_input.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  File? _userImageFile;
  var isLoading = false;

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_isLogin && _userImageFile == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick an image.'),
          // backgroundColor: Theme.of(context).errorColor,
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    try {
      setState(() {
        isLoading = true;
      });
      if (_isLogin) {
        final userCredentials = _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
        // Sign in the user with Firebase Authentication.
      } else {
        final response = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        //upload image to firebase storage
        if (response.user != null && _userImageFile != null) {
          // Upload the image to Firebase Storage.
          // Get the download URL of the image.
          // Save the user data to Firestore.
          final imageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('${response.user!.uid}.jpg');
          await imageRef.putFile(_userImageFile!);
          final imageUrl = await imageRef.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('users')
              .doc(response.user!.uid)
              .set({
            'username': _enteredUsername,
            'email': _enteredEmail,
            'image_url': imageUrl,
          });
          // Save the user data to Firestore.
          // You can use the imageUrl to store the image URL in Firestore.
        }
      }
    } catch (error) {
      var message = 'An error occurred, please check your credentials!';

      if (error is FirebaseAuthException) {
        if (error.code == 'email-already-in-use') {
          message = 'This email address is already in use.';
        } else if (error.code == 'weak-password') {
          message = 'The password provided is too weak.';
        }
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          // backgroundColor: Theme.of(context).errorColor,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    bottom: 20, top: 30, left: 20, right: 20),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            ImageInput(
                              onSelectImage: (image) => _userImageFile = image,
                            ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            enableSuggestions: false,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          if (!_isLogin)
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Username'),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null || value.trim().length < 4) {
                                  return 'Please enter a valid username.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredUsername = value!;
                              },
                            ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be at least 6 characters long.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (isLoading) const CircularProgressIndicator(),
                          if (!isLoading)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: Text(_isLogin ? 'Login' : 'Sign Up'),
                            ),
                          if (!isLoading)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin
                                  ? 'Create an account'
                                  : 'Already have an account?'),
                            ),
                        ],
                      ),
                    ),
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
