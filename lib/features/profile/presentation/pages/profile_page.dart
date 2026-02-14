import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/preferences/chinese_preference.dart';
import '../../../../core/user/user_manager.dart';
import '../../../../core/utils/chinese_converter.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../about/data/app_package_info.dart';
import '../../../../core/utils/constants/numbers.dart';
import '../../../../core/utils/extensions/snack_bar_extension.dart';
import '../../../../core/utils/functions/calculate_max_width.dart';
import '../../../../core/utils/resources/supabase.dart';
import '../../../../core/widgets/custom_elevated_button.dart';
import '../../../../core/widgets/text_field.dart';
import '../../data/data_sources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../about/presentation/dialogs/supa_quiz_about_dialog.dart';
import '../../../../core/widgets/user_bubble.dart';

@RoutePage()
class ProfilePage extends StatefulHookWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  int _versionTapCount = 0;
  Timer? _versionTapResetTimer;
  bool _isTraditional = false;

  @override
  void initState() {
    super.initState();
    ChinesePreference.loadIsTraditional().then((v) {
      if (mounted) setState(() => _isTraditional = v);
    });
  }

  String _t(String s) => convertChinese(s, _isTraditional);

  Future<void> _onSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('退出登录')),
        content: Text(_t('确定要退出当前登录吗？')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('取消')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_t('确定')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<UserManager>().clear();
    await supabase.auth.signOut();
    // app_shell 监听 signOut 事件，会自动 replaceAll 到 AuthRoute（登录页）
  }

  @override
  void dispose() {
    _versionTapResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final usernameController = useTextEditingController(
      text: user?.userMetadata?['username'],
    );
    final widgetState = useState<int>(0);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && supabase.auth.currentUser == null) {
          context.router.push(const AuthRoute());
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Page"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const SupaQuizAboutDialog(),
              );
            },
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: kDefaultPadding),
        ],
      ),
      body: Center(
        child: Container(
          width: calculateMaxWidth(context),
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UserBubble(
                username: usernameController.text.isEmpty
                    ? "U"
                    : usernameController.text,
              ),
              const SizedBox(height: kHugePadding),
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: SupaTextField(
                    label: "Username",
                    controller: usernameController,
                    keyboardType: TextInputType.name,
                    onChanged: (_) => widgetState.value = widgetState.value + 1,
                    isEmptyError: "Please enter a username",
                  ),
                ),
              ),
              CustomElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  if (usernameController.text.length < 3) {
                    context.showSnackBar(
                      message: "Username must be at least 3 characters",
                    );
                    return;
                  }

                  if (usernameController.text ==
                      user.userMetadata?['username']) {
                    context.showSnackBar(
                      message: "The username is the same as before",
                    );
                    return;
                  }

                  final result = await ProfileRepositoryImpl(
                    remoteDataSource: ProfileRemoteDataSourceImpl(),
                  ).updateProfile(
                    username: usernameController.text,
                  );

                  result.fold(
                    (failure) => {
                      context.showSnackBar(
                        message: failure.errorMessage,
                      ),
                    },
                    (_) {
                      context.showSnackBar(
                        message: "Profile updated!",
                        background: AppColors.primary,
                        foreground: Colors.black,
                      );
                    },
                  );

                  widgetState.value = widgetState.value + 1;
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Update Profile", style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: kHugePadding),
              const Spacer(),
              OutlinedButton(
                onPressed: () => _onSignOut(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: Text(_t('退出登录'), style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: kHugePadding),
              GestureDetector(
                onTap: () {
                  _versionTapResetTimer?.cancel();
                  setState(() {
                    _versionTapCount++;
                    if (_versionTapCount >= 5) {
                      _versionTapCount = 0;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('身份验证成功，欢迎 Boss！'),
                          backgroundColor: Colors.green,
                          duration: const Duration(milliseconds: 500),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      context.router.push(const AdminReviewRoute());
                    } else {
                      if (_versionTapCount >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('再点 ${5 - _versionTapCount} 次进入管理模式'),
                            duration: const Duration(milliseconds: 500),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      _versionTapResetTimer = Timer(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _versionTapCount = 0);
                      });
                    }
                  });
                },
                child: Text(
                  'Version ${AppPackageInfo().packageInfo.version}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
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
