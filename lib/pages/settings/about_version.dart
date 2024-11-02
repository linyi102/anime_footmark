import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/logo.dart';
import 'package:flutter_test_future/models/enum/load_status.dart';
import 'package:flutter_test_future/pages/changelog/view.dart';
import 'package:flutter_test_future/services/update_service.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/values/assets.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:flutter_test_future/widgets/svg_asset_icon.dart';

class AboutVersion extends StatefulWidget {
  const AboutVersion({Key? key}) : super(key: key);

  @override
  _AboutVersionState createState() => _AboutVersionState();
}

class _AboutVersionState extends State<AboutVersion> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("关于版本"),
      ),
      body: CommonScaffoldBody(child: _buildBody(context)),
    );
  }

  Stack _buildBody(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: [
            Column(
              children: [
                const Logo(),
                Text("当前版本: ${AppUpdateService.to.curVersion}"),
                _buildWebsiteIconsRow(context),
              ],
            ),
            ValueListenableBuilder(
              valueListenable: AppUpdateService.to.checkStatus,
              builder: (context, checkStatus, child) => ListTile(
                onTap: checkStatus == LoadStatus.loading
                    ? null
                    : () => AppUpdateService.to
                        .checkLatestRelease(context: context),
                title: const Text("检查更新"),
                trailing: checkStatus == LoadStatus.loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.4))
                    : null,
              ),
            ),
            ListTile(
                title: const Text("更新日志"),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChangelogPage()));
                }),
            ListTile(
                title: const Text("下载地址"),
                subtitle: const Text("密码：eocv"),
                trailing: const Icon(EvaIcons.externalLink),
                onTap: () {
                  LaunchUrlUtil.launch(
                      context: context,
                      uriStr: "https://wwc.lanzouw.com/b01uyqcrg?password=eocv",
                      inApp: false);
                }),
            ListTile(
                title: const Text("QQ 交流群"),
                subtitle: const Text("414226908"),
                trailing: const Icon(EvaIcons.externalLink),
                onTap: () {
                  LaunchUrlUtil.launch(
                      context: context,
                      uriStr: "https://jq.qq.com/?_wv=1027&k=qOpUIx7x",
                      inApp: false);
                }),
          ],
        ),
      ],
    );
  }

  Row _buildWebsiteIconsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          splashRadius: 20,
          onPressed: () {
            LaunchUrlUtil.launch(
                context: context,
                uriStr: "https://github.com/linyi102/anime_trace");
          },
          icon: SvgAssetIcon(
            assetPath: Assets.iconsGithub,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        IconButton(
          splashRadius: 20,
          onPressed: () {
            LaunchUrlUtil.launch(
                context: context,
                uriStr: "https://gitee.com/linyi517/anime_trace",
                inApp: false);
          },
          icon: const SvgAssetIcon(
            assetPath: Assets.iconsGitee,
            color: Color.fromRGBO(187, 33, 36, 1),
          ),
        )
      ],
    );
  }
}
