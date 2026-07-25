import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tribe_up/config/di/di.dart';
import 'package:tribe_up/core/constants/app_routes_constants.dart';
import 'package:tribe_up/core/constants/ui_constants.dart';
import 'package:tribe_up/core/resources/color_manager.dart';
import 'package:tribe_up/core/utils/ui_utils.dart';
import 'package:tribe_up/features/auth/presentation/cubit/login/login_cubit.dart';
import 'package:tribe_up/features/auth/presentation/cubit/login/login_intents.dart';
import 'package:tribe_up/features/auth/presentation/cubit/login/login_states.dart';
import 'package:tribe_up/features/auth/presentation/cubit/login/login_ui_intents.dart';
import 'package:tribe_up/features/auth/presentation/widgets/shared/email_field_widget.dart';
import 'package:tribe_up/features/auth/presentation/widgets/login/login_button_widget.dart';
import 'package:tribe_up/features/auth/presentation/widgets/shared/password_field_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginCubit _loginCubit;
  final formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loginCubit = getIt<LoginCubit>();
    _email.clear();
    _password.clear();

    _loginCubit.uiIntents.listen((event) {
      if (!mounted) return;

      switch (event) {
        case ShowLoadingIntent():
          UIUtils.showDotLottieLoadingOverlay(context);

        case ShowErrorIntent(message: final message):
          UIUtils.hideLoading(context);
          UIUtils.showPremiumMessage(
            context,
            message,
            backgroundColor: ColorManager.red,
            icon: Icons.error,
          );
          break;
        case NavigateToFeedIntent():
          UIUtils.hideLoading(context);
          UIUtils.showPremiumMessage(context, UiConstants.welcomeToTribeUp);
          context.goNamed(AppRoutesConstants.feed, extra: event.userSummary);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocProvider.value(
        value: _loginCubit,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Text(
                    UiConstants.createAccountMessage,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30),
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 7),
                        EmailFieldWidget(
                          controller: _email,
                          onChanged: (v) =>
                              _loginCubit.doIntent(EmailChanged(v)),
                        ),
                        SizedBox(height: 5),
                        PasswordFieldWidget(
                          password: _password,
                          onChanged: (v) =>
                              _loginCubit.doIntent(PasswordChanged(v)),
                        ),
                        InkWell(
                          onTap: () => context.pushNamed(
                            AppRoutesConstants.forgetPassword,
                          ),
                          child: Text(
                            UiConstants.forgottenPassword,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                        SizedBox(height: 10),
                        BlocBuilder<LoginCubit, LoginStates>(
                          builder: (_, state) {
                            return LoginButtonWidget(
                              cubit: _loginCubit,
                              formKey: formKey,
                              state: state,
                            );
                          },
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              context.pushReplacementNamed(
                                AppRoutesConstants.signUp,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.white,
                              foregroundColor: ColorManager.black,
                              side: BorderSide(color: ColorManager.black),
                            ),
                            child: Text(
                              UiConstants.createAccount,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                        SizedBox(height: 350),
                        Center(
                          child: Text(
                            UiConstants.tribeUp,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }
}
