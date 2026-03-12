import 'package:fluffychat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';

import 'package:fluffychat/widgets/layouts/login_scaffold.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'login.dart';

class LoginView extends StatelessWidget {
  final LoginController controller;

  const LoginView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    return LoginScaffold(
      appBar: AppBar(
        leading: controller.loading ? null : const BackButton(),
        automaticallyImplyLeading: !controller.loading,
      ),
      body: SafeArea(
        child: AutofillGroup(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    Text(
                      l10n.welcomeBack,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: LinagoraSysColors.material().onBackground,
                          ),
                    ),
                    FutureBuilder(
                      future: controller.loginClientFuture,
                      builder: (context, asyncSnapshot) {
                        if (asyncSnapshot.hasError) {
                          return const SizedBox.shrink();
                        }
                        final homeserver =
                            asyncSnapshot.data?.homeserver
                                ?.toString()
                                .replaceFirst('https://', '') ??
                            '';
                        if (homeserver.isEmpty &&
                            asyncSnapshot.connectionState ==
                                ConnectionState.done) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          homeserver,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color:
                                    LinagoraSysColors.material().onBackground,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      readOnly: controller.loading,
                      autocorrect: false,
                      autofocus: true,
                      onChanged: controller.checkWellKnownWithCoolDown,
                      contextMenuBuilder: mobileTwakeContextMenuBuilder,
                      controller: controller.usernameController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: controller.loading
                          ? null
                          : [AutofillHints.username],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        focusedBorder: controller.usernameError != null
                            ? OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                  width: 2.0,
                                ),
                              )
                            : null,
                        labelText: l10n.emailOrUsername,
                        labelStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: controller.usernameError != null
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                        hintText: l10n.emailOrUsername,
                        contentPadding: const EdgeInsets.all(16.0),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        controller.usernameError ?? '',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      readOnly: controller.loading,
                      autocorrect: false,
                      autofillHints: controller.loading
                          ? null
                          : [AutofillHints.password],
                      contextMenuBuilder: mobileTwakeContextMenuBuilder,
                      controller: controller.passwordController,
                      textInputAction: TextInputAction.go,
                      obscureText: !controller.showPassword,
                      onSubmitted: (_) => controller.login(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        focusedBorder: controller.passwordError != null
                            ? OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                  width: 2.0,
                                ),
                              )
                            : null,
                        labelText: l10n.password,
                        labelStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: controller.passwordError != null
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                        hintText: l10n.password,
                        contentPadding: const EdgeInsets.all(16.0),
                        suffixIcon: IconButton(
                          onPressed: controller.toggleShowPassword,
                          icon: Icon(
                            controller.showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        controller.passwordError ?? '',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4.0),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Hero(
                      tag: 'signInButton',
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          maximumSize: const Size.fromHeight(40),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        onPressed: controller.loading ? null : controller.login,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (controller.loading)
                              const Expanded(child: LinearProgressIndicator())
                            else
                              Text(
                                l10n.signIn,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      letterSpacing: 0.1,
                                    ),
                              ),
                          ],
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
    );
  }
}
