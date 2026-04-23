import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:food_delivery/view/shared/login/rest_password_view.dart';
import 'package:food_delivery/view/shared/login/sing_up_view.dart';
import 'package:food_delivery/view/shared/on_boarding/on_boarding_view.dart';

import '../../../common/service_call.dart';
import '../../../common_widget/round_textfield.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController txtTenDangNhap = TextEditingController();
  TextEditingController txtPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 64,
              ),
              Text(
                "Login",
                style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 30,
                    fontWeight: FontWeight.w800),
              ),
              Text(
                "Add your details to login",
                style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                height: 25,
              ),
              RoundTextfield(
                hintText: "Tên đăng nhập",
                controller: txtTenDangNhap,
              ),
              const SizedBox(
                height: 25,
              ),
              RoundTextfield(
                hintText: "Password",
                controller: txtPassword,
                obscureText: true,
              ),
              const SizedBox(
                height: 25,
              ),
              RoundButton(
                  title: "Login",
                  onPressed: () {
                    btnLogin();
                  }),
              const SizedBox(
                height: 4,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordView(),
                    ),
                  );
                },
                child: Text(
                  "Forgot your password?",
                  style: TextStyle(
                      color: TColor.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              const SizedBox(
                height: 40,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpView(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Don't have an Account? ",
                      style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "Sign Up",
                      style: TextStyle(
                          color: TColor.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //TODO: Action
  void btnLogin() {
    if (txtTenDangNhap.text.isEmpty) {
      mdShowAlert(Globs.appName, "Vui lòng nhập tên đăng nhập.", () {});
      return;
    }

    if (txtPassword.text.isEmpty) {
      mdShowAlert(Globs.appName, "Please enter your password.", () {});
      return;
    }

    endEditing();

    serviceCallLogin({
      "tenDangNhap": txtTenDangNhap.text,
      "matKhau": txtPassword.text,
      "push_token": ""
    });
  }

  //TODO: ServiceCall

  void serviceCallLogin(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(parameter, SVKey.svLogin, withSuccess: (responseObj) async {
      Globs.hideHUD();
      final userObj = Map<String, dynamic>.from(responseObj["user"] as Map? ??
          responseObj[KKey.payload] as Map? ??
          {});
      final sessionObj = responseObj["session"] as Map? ?? {};
      final authToken = responseObj["token"] as String? ??
          sessionObj["token"] as String? ??
          responseObj[KKey.authToken] as String? ??
          "";

      if (userObj.isNotEmpty) {
        final normalizedUser = Map<String, dynamic>.from(userObj);
        normalizedUser.putIfAbsent(
            KKey.name, () => normalizedUser["fullName"] ?? "");

        Globs.udSet(normalizedUser, Globs.userPayload);
        ServiceCall.userPayload = normalizedUser;
        Globs.udBoolSet(true, Globs.userLogin);
        if (authToken.isNotEmpty) {
          Globs.udStringSet(authToken, KKey.authToken);
        }

          Navigator.pushAndRemoveUntil(context,  MaterialPageRoute(
            builder: (context) => const OnBoardingView(),
          ), (route) => false);
      } else {
        mdShowAlert(Globs.appName,
            responseObj[KKey.message] as String? ?? MSG.fail, () {});
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    });
  }
}
