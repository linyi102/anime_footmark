import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/components/rounded_sheet.dart';

/// 动漫详情页ui和集排序设置
class AnimeDetailUISettingPage extends StatefulWidget {
  const AnimeDetailUISettingPage(
      {required this.sortPage, required this.uiPage, super.key});
  final Widget sortPage;
  final Widget uiPage;

  @override
  State<AnimeDetailUISettingPage> createState() =>
      _AnimeDetailUISettingPageState();
}

class _AnimeDetailUISettingPageState extends State<AnimeDetailUISettingPage>
    with SingleTickerProviderStateMixin {
  final List<String> tabStr = ["排序", "界面"];

  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabStr.length, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoundedSheet(
        title: CommonBottomTabBar(
            tabController: tabController,
            tabs: tabStr.map((e) => Tab(text: e)).toList()),
        body: TabBarView(controller: tabController, children: [
          widget.sortPage,
          widget.uiPage,
        ]));
  }
}
