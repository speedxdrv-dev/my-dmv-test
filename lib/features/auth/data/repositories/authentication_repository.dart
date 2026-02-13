import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/errors/exeptions.dart';
import '../../../../core/utils/extensions/snack_bar_extension.dart';
import '../../../../core/utils/resources/supabase.dart';

abstract class AuthenticationRepository {
  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  });

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required BuildContext context,
  });

  /// 先尝试登录，若用户不存在则自动注册
  Future<void> signInOrSignUp({
    required String email,
    required String password,
    required String username,
    required BuildContext context,
  });
}

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  static final AuthenticationRepositoryImpl _instance =
      AuthenticationRepositoryImpl._internal();

  factory AuthenticationRepositoryImpl() {
    return _instance;
  }

  AuthenticationRepositoryImpl._internal();

  @override
  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // 登录成功，auth 状态变化会触发导航；此处提示用户
      if (context.mounted) {
        context.showSnackBar(
          message: '登录成功',
          background: AppColors.green,
          foreground: Colors.white,
        );
      }
    } on AuthApiException catch (e) {
      if (context.mounted) {
        context.showSnackBar(message: e.message);
      }
    } catch (e) {
      log("Failed to authenticate: $e, Error type: ${e.runtimeType}");
      if (context.mounted) {
        context.showSnackBar(message: '登录失败: $e');
      }
    }
  }

  @override
  Future<void> signInOrSignUp({
    required String email,
    required String password,
    required String username,
    required BuildContext context,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (context.mounted) {
        context.showSnackBar(
          message: '登录成功',
          background: AppColors.green,
          foreground: Colors.white,
        );
      }
    } on AuthException catch (_) {
      // 登录失败，不报错，立即尝试注册
      try {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {"username": username},
        );
        await _createEntryInDatabase(response);
        if (context.mounted) {
          context.showSnackBar(
            message: '注册成功',
            background: AppColors.green,
            foreground: Colors.white,
          );
        }
      } on AuthException catch (signUpError) {
        if (context.mounted) {
          context.showSnackBar(message: '注册失败：${signUpError.message}');
        }
      } on ServerException catch (e2) {
        if (context.mounted) {
          context.showSnackBar(message: e2.message ?? 'Server Error');
        }
      }
    } catch (e) {
      log("Failed to authenticate: $e, Error type: ${e.runtimeType}");
      if (context.mounted) {
        context.showSnackBar(message: '登录失败: $e');
      }
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required BuildContext context,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {"username": username},
      );

      await _createEntryInDatabase(response);
    } on AuthApiException catch (e) {
      if (context.mounted) {
        context.showSnackBar(message: e.message);
      }
    } on ServerException catch (e) {
      if (context.mounted) {
        context.showSnackBar(message: e.message ?? 'Server Error');
      }
    } catch (e) {
      log("Failed to authenticate: $e, Error type: ${e.runtimeType}");
    }
  }

  /// Onyl used when signing up
  Future<void> _createEntryInDatabase(AuthResponse response) async {
    try {
      await supabase.from('users').insert({
        'user_id': response.user!.id,
        'username': response.user!.userMetadata!['username'],
        'quizzes': [],
      });
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      // If an unexpected error occurs, print the type of the error
      log(
        "Error with _createEntryInDatabase: $e, Error type: ${e.runtimeType}",
      );
    }
  }
}
