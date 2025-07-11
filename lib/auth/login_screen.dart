import 'package:flutter/material.dart';
import 'package:klayons/utils/styles/button.dart';
import 'package:klayons/utils/styles/checkbox.dart';
import 'package:klayons/utils/styles/klayonsFont.dart';
import 'package:klayons/utils/styles/textButton.dart';
import 'package:klayons/utils/styles/textboxes.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isAgreeChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Top section with profile icon
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom section with form
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 24),

                      // Email/Phone input field
                      CustomTextField(
                        hintText: "Email or Phone",
                        controller: _emailController,
                      ),

                      SizedBox(height: 24),

                      // Terms and Privacy Policy
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomeCheckbox(
                            value: _isAgreeChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                _isAgreeChecked = value ?? false;
                              });
                            },
                          ),
                          Row(
                            children: [
                              Text("By clicking , I agree to the "),
                              CustomTextButton(
                                text: "Privacy  policy",
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 32),

                      // Send OTP Button
                      SizedBox(
                        width: double.infinity,
                        child: OrangeButton(
                          onPressed:
                              _isAgreeChecked &&
                                  _emailController.text.isNotEmpty
                              ? () {}
                              : null,
                          child: Text("Send OTP"),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Register link
                      Center(
                        child: Row(
                          children: [
                            Text("Don't have an account? "),
                            CustomTextButton(
                              text: "Register Here",
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),

                      Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
