import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen.login({this.redirectLocation, super.key}) : isSignUp = false;

  const AuthScreen.signUp({this.redirectLocation, super.key}) : isSignUp = true;

  final bool isSignUp;
  final String? redirectLocation;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isLoading = auth.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(next.error!))));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/figma/app_icon.png',
                      width: 72,
                      height: 72,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'HEIMDALL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.isSignUp
                          ? '토론을 시작할 계정을 만들어주세요.'
                          : '계정으로 로그인해 토론에 참여하세요.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (widget.isSignUp) ...[
                      TextFormField(
                        controller: _displayNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: '닉네임'),
                        validator: (value) {
                          final length = value?.trim().length ?? 0;
                          if (length < 2 || length > 20) {
                            return '닉네임은 2자 이상 20자 이하로 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: '성별 (선택)',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'MALE',
                                  child: Text('남성'),
                                ),
                                DropdownMenuItem(
                                  value: 'FEMALE',
                                  child: Text('여성'),
                                ),
                                DropdownMenuItem(
                                  value: 'OTHER',
                                  child: Text('기타'),
                                ),
                              ],
                              onChanged: isLoading
                                  ? null
                                  : (value) => setState(() => _gender = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              decoration: const InputDecoration(
                                labelText: '나이 (선택)',
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return null;
                                final age = int.tryParse(text);
                                if (age == null || age < 0 || age > 150) {
                                  return '0~150 사이로 입력해주세요.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: '이메일'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (!RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(email)) {
                          return '올바른 이메일을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => isLoading ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final minimum = widget.isSignUp ? 8 : 1;
                        if ((value?.length ?? 0) < minimum) {
                          return widget.isSignUp
                              ? '비밀번호는 8자 이상 입력해주세요.'
                              : '비밀번호를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isSignUp ? '회원가입' : '로그인'),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go(
                              _authRoute(
                                widget.isSignUp ? '/login' : '/signup',
                              ),
                            ),
                      child: Text(
                        widget.isSignUp ? '이미 계정이 있나요? 로그인' : '처음이신가요? 회원가입',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _authRoute(String path) {
    return Uri(
      path: path,
      queryParameters: widget.redirectLocation == null
          ? null
          : {'redirect': widget.redirectLocation!},
    ).toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isSignUp) {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _displayNameController.text,
            gender: _gender,
            age: _ageController.text.trim().isEmpty
                ? null
                : int.parse(_ageController.text.trim()),
          );
    } else {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            email: _emailController.text,
            password: _passwordController.text,
          );
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (error.response?.statusCode == 409) {
        return '이미 가입된 이메일입니다.';
      }
      if (error.response?.statusCode == 401) {
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      }
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return '서버에 연결할 수 없습니다. 백엔드와 API 주소를 확인해주세요.';
      }
    }
    return '요청을 처리하지 못했습니다. 잠시 후 다시 시도해주세요.';
  }
}
