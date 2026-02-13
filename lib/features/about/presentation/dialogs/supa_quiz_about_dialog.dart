import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/config/supabase/setup.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/constants/numbers.dart';
import '../../../../core/utils/constants/strings.dart';
import '../../../../core/utils/functions/custom_launch_url.dart';
import '../../../profile/presentation/widgets/dialog_list_tile.dart';
import '../../data/app_package_info.dart';

class SupaQuizAboutDialog extends StatelessWidget {
  const SupaQuizAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AboutDialog(
      applicationName: kAppName,
      applicationVersion: AppPackageInfo().packageInfo.version,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        child: SizedBox.square(
          dimension: 60,
          child: Image.asset(
            kAppIconUrl,
          ),
        ),
      ),
      children: [
        Text(
          "Supabase: $kSupabaseUrl",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: kDefaultPadding),
        Text(
          "Support:",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: kDefaultPadding),
        DialogListTile(
          title: "再次查看介绍",
          icon: const Icon(Icons.menu_book_rounded),
          onTap: () {
            Navigator.of(context).pop();
            context.router.push(const IntroRoute());
          },
        ),
        DialogListTile(
          title: "Leave a star on Github",
          icon: const Icon(Icons.star_rounded, color: AppColors.primary),
          onTap: () async {
            await customLaunchUrl(kGitHubRepoUrl, context);
          },
        ),
        DialogListTile(
          title: "Image from studio4rt on Freepik",
          icon: const Icon(Icons.image_rounded),
          onTap: () async {
            await customLaunchUrl(kFreepikImageUrl, context);
          },
        ),
      ],
    );
  }

  
}
