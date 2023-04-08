import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_item_auto_load.dart';
import 'package:flutter_test_future/components/bottom_sheet.dart';
import 'package:flutter_test_future/components/common_tab_bar.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/components/search_app_bar.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/pages/network/sources/pages/import/import_collection_controller.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/site_collection_tab.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:timer_count_down/timer_count_down.dart';

class ImportCollectionPage extends StatefulWidget {
  const ImportCollectionPage({required this.climbWebsite, super.key});
  final ClimbWebsite climbWebsite;

  @override
  State<ImportCollectionPage> createState() => _ImportCollectionPagrState();
}

/// 必须使用有状态组件，因为要TabController要使用SingleTickerProviderStateMixin里的this
class _ImportCollectionPagrState extends State<ImportCollectionPage>
    with SingleTickerProviderStateMixin {
  late ImportCollectionController icc;

  String get getxTag => widget.climbWebsite.name;
  int get curCollIdx => icc.tabController!.index;
  ClimbWebsite get climbWebsite => icc.climbWebsite;
  Climb get climb => icc.climbWebsite.climb;
  List<SiteCollectionTab> get siteCollectionTab =>
      icc.climbWebsite.climb.siteCollectionTabs;

  @override
  void initState() {
    icc =
        Get.put(ImportCollectionController(widget.climbWebsite), tag: getxTag);

    icc.tabController ??= TabController(
      length: siteCollectionTab.length,
      vsync: this,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: GetBuilder(
        id: ImportCollectionController.bodyId,
        tag: getxTag,
        init: icc,
        builder: (_) => _buildBody(),
      ),
    );
  }

  _buildBody() {
    if (icc.showTip) {
      return ListView(
        children: [
          ListTile(
            leading: WebSiteLogo(url: climbWebsite.iconUrl, size: 25),
            title: Text(climbWebsite.name),
          ),
          const ListTile(
            title: Text("这个可以做什么？"),
            subtitle:
                Text("如果你之前在Bangumi或豆瓣中收藏过很多电影或动漫，该功能可以帮忙把这些数据导入到漫迹中，而不需要手动添加"),
          ),
          const ListTile(
            title: Text("如何获取用户ID？"),
            subtitle: Text(
                "在Bangumi中查看自己的信息时，访问的链接若为https://bangumi.tv/user/123456，那么该用户的ID就是123456"),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (!icc.showTip) _buildTabBar(),
        Expanded(child: _buildTabBarView(context)),
        _buildBottomBar(context)
      ],
    );
  }

  _buildTabBar() {
    return CommonBottomTabBar(
      bgColor: ThemeUtil.getAppBarBackgroundColor(),
      isScrollable: true,
      tabs: List.generate(
        siteCollectionTab.length,
        (collIdx) => Tab(
          text:
              "${siteCollectionTab[collIdx].title} (${icc.userCollection[collIdx].totalCnt})",
        ),
      ),
      tabController: icc.tabController,
    );
  }

  _buildTabBarView(BuildContext context) {
    return TabBarView(
      controller: icc.tabController,
      children: List.generate(siteCollectionTab.length, (collIdx) {
        if (icc.searching[collIdx]) return loadingWidget(context);
        if (icc.userCollection[collIdx].animes.isEmpty) {
          return emptyDataHint(msg: "没有收藏。");
        }

        return SmartRefresher(
          controller: icc.refreshControllers[collIdx],
          enablePullDown: true,
          enablePullUp: true,
          onRefresh: () => icc.onRefresh(collIdx),
          onLoading: () => icc.loadMore(collIdx),
          child: _buildAnimeListView(collIdx),
        );
      }),
    );
  }

  ListView _buildAnimeListView(int collIdx) {
    return ListView.builder(
        itemCount: icc.userCollection[collIdx].animes.length,
        itemBuilder: (context, animeIdx) {
          Anime anime = icc.userCollection[collIdx].animes[animeIdx];
          return _buildAnimeItem(anime);
        });
  }

  _buildAppBar() {
    return AppBar(
      title: SearchAppBar(
        inputController: icc.inputController,
        useModernStyle: false,
        hintText: "用户ID",
        isAppBar: false,
        autofocus: icc.showTip, // 如果显示提示，则自动聚焦输入框
        onTapClear: () {
          icc.inputController.clear();
        },
        onEditingComplete: () => icc.onEditingComplete(),
      ),
    );
  }

  /// 一键添加当前tab下的所有收藏
  /// 提示选择清单
  /// 注意要把curCollIdx作为参数传进来，避免加载更多时切换tab导致加载了其他tab动漫
  _showBottomSelectChecklist(BuildContext context, int collIdx) {
    if (icc.userCollection[curCollIdx].totalCnt == 0) {
      showToast("没有收藏的动漫");
      return;
    }

    if (icc.quickCollecting) {
      showToast("收藏中，请稍后再试");
      return;
    }

    final scrollController = ScrollController();

    return showCommonBottomSheet(
        context: context,
        expanded: true,
        title: Text("一键收藏 “${siteCollectionTab[collIdx].title}” 到"),
        child: Column(
          children: [
            StatefulBuilder(
              builder: (context, setState) => SwitchListTile(
                title: const Text("若已收藏同名动漫，则跳过"),
                value: SpProfile.getSkipDupNameAnime(),
                onChanged: (value) {
                  SpProfile.setSkipDupNameAnime(value);
                  setState(() {});
                },
              ),
            ),
            const Divider(),
            Expanded(
              child: Scrollbar(
                controller: scrollController,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    var tag = tags[index];

                    return ListTile(
                        title: Text(tag),
                        onTap: () => icc.quickCollect(context, collIdx, tag));
                  },
                ),
              ),
            ),
          ],
        ));
  }

  _buildBottomBar(BuildContext context) {
    return GetBuilder(
        tag: getxTag,
        id: ImportCollectionController.bottomBarId,
        init: icc,
        builder: (_) {
          // 剩余页数/页大小，每页预计耗时6s(1s获取 + 5s间隔)
          int seconds =
              (icc.totalPage - icc.curPage + 1) * (icc.gap.inSeconds + 1);

          return ListTile(
            leading: _buildBottomBarWebsiteIcon(),
            title: Text.rich(TextSpan(children: [
              WidgetSpan(child: Text("页数 ${icc.curPage}/${icc.totalPage}")),
              if (icc.quickCollecting)
                TextSpan(children: [
                  const WidgetSpan(child: Text("，预计 ")),
                  WidgetSpan(
                      child: Countdown(
                    seconds: seconds,
                    build: (context, value) => Text(
                        TimeUtil.getReadableDuration(
                            Duration(seconds: value.toInt()))),
                  )),
                ]),
              const TextSpan(text: "\n"),
              WidgetSpan(
                  child:
                      Text("成功 ${icc.addOk}，跳过 ${icc.added}，失败 ${icc.addFail}"))
            ])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (icc.addFail > 0)
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _buildFailedAnimeList(),
                            ));
                      },
                      child: const Text("查看失败")),
                icc.quickCollecting
                    ? icc.stopping
                        ? const Text("取消中")
                        : TextButton(
                            onPressed: () => icc.cancelQuickCollect(context),
                            child: const Text("取消"))
                    : TextButton(
                        onPressed: () =>
                            _showBottomSelectChecklist(context, curCollIdx),
                        child: const Text("收藏")),
              ],
            ),
          );
        });
  }

  SizedBox _buildBottomBarWebsiteIcon() {
    const double size = 30;

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          if (icc.quickCollecting)
            const SizedBox(
              height: size,
              width: size,
              child: CircularProgressIndicator(),
            ),
          WebSiteLogo(url: climbWebsite.iconUrl, size: size)
        ],
      ),
    );
  }

  Scaffold _buildFailedAnimeList() {
    return Scaffold(
        appBar: AppBar(
            title: const Text("失败列表",
                style: TextStyle(fontWeight: FontWeight.w600))),
        body: ListView.builder(
            itemCount: icc.failedAnimes.length,
            itemBuilder: (context, animeIdx) {
              Anime anime = icc.failedAnimes[animeIdx];
              return _buildAnimeItem(anime);
            }));
  }

  AnimeItemAutoLoad _buildAnimeItem(Anime anime) {
    return AnimeItemAutoLoad(
      anime: anime,
      climbDetail: false, // 频繁爬取会导致豆瓣提示拒绝执行
      subtitles: [
        anime.nameAnother,
        anime.tempInfo ?? "",
      ],
      showProgress: false,
      onChanged: (newAnime) {
        anime = newAnime;
        if (mounted) setState(() {});
      },
    );
  }
}
