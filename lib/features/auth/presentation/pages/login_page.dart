import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:brecho_express_app/core/design_system/tokens.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.primary.withAlpha(10),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: AppSizes.icon + 4,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              'BE',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Brechó Express',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Seu achado chegou.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Informe o e-mail';
                                }
                                if (!RegExp(
                                  r"^[\w-.]+@[\w-]+\.[a-z]{2,}$",
                                  caseSensitive: false,
                                ).hasMatch(v)) {
                                  return 'E-mail inválido';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _passCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Informe a senha';
                                }
                                if (v.length < 6) {
                                  return 'Senha muito curta';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submit,
                                child: const Text('Entrar'),
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Criar conta'),
                                      content: const Text(
                                        'Funcionalidade de criação de conta em desenvolvimento.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: const Text('Fechar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Criar conta'),
                              ),
                            ),
                            SizedBox(height: AppSpacing.md),
                            // separador
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                SizedBox(width: AppSpacing.sm),
                                const Text('ou continue com'),
                                SizedBox(width: AppSpacing.sm),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            SizedBox(height: AppSpacing.sm),
                            // botões sociais
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth > 420;
                                Widget googleButton = OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Login social será implementado em breve.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.g_translate),
                                  label: const Text('Continuar com Google'),
                                );

                                Widget facebookButton = OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Login social será implementado em breve.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.facebook),
                                  label: const Text('Continuar com Facebook'),
                                );

                                if (wide) {
                                  return Row(
                                    children: [
                                      Expanded(child: googleButton),
                                      SizedBox(width: AppSpacing.sm),
                                      Expanded(child: facebookButton),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: googleButton,
                                    ),
                                    SizedBox(height: AppSpacing.sm),
                                    SizedBox(
                                      width: double.infinity,
                                      child: facebookButton,
                                    ),
                                  ],
                                );
                              },
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
        ),
      ),
    );
  }
}
