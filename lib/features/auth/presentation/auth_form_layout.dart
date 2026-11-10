import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';

const Color authPrimaryColor = Color(0xFF2864F0);

class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.title,
    required this.isRegister,
    required this.formKey,
    required this.formFields,
    required this.footerText,
    required this.footerAction,
    required this.footerRoute,
  });

  final String title;
  final bool isRegister;
  final GlobalKey<FormState> formKey;
  final List<Widget> formFields;
  final String footerText;
  final String footerAction;
  final String footerRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextButton.icon(
                  onPressed: () => context.go(Routes.landing),
                  style: TextButton.styleFrom(
                    foregroundColor: authPrimaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text(
                    'Kembali',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight > 40
                            ? constraints.maxHeight - 40
                            : 0,
                      ),
                      child: IntrinsicHeight(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 497),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Form(
                                key: formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _AuthModeSelector(isRegister: isRegister),
                                    const SizedBox(height: 30),
                                    ...formFields,
                                    const Spacer(),
                                    const SizedBox(height: 20),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          footerText,
                                          style: const TextStyle(
                                            color: Color(0xFF718096),
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              context.go(footerRoute),
                                          style: TextButton.styleFrom(
                                            foregroundColor: authPrimaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            textStyle: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          child: Text(footerAction),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthModeSelector extends StatelessWidget {
  const _AuthModeSelector({required this.isRegister});

  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          _AuthModeButton(
            label: 'Login',
            route: Routes.login,
            selected: !isRegister,
          ),
          _AuthModeButton(
            label: 'Daftar',
            route: Routes.register,
            selected: isRegister,
          ),
        ],
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.label,
    required this.route,
    required this.selected,
  });

  final String label;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox.expand(
        child: TextButton(
          onPressed: selected ? null : () => context.go(route),
          style: TextButton.styleFrom(
            backgroundColor: selected ? authPrimaryColor : Colors.transparent,
            foregroundColor: selected ? Colors.white : const Color(0xFF718096),
            disabledForegroundColor: Colors.white,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

InputDecoration authInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: authPrimaryColor),
    ),
  );
}
