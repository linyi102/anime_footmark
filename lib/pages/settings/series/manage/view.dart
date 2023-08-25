import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/dao/anime_series_dao.dart';
import 'package:flutter_test_future/pages/settings/series/form/view.dart';
import 'package:flutter_test_future/pages/settings/series/manage/style.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/widgets/setting_title.dart';
import 'package:flutter_test_future/widgets/svg_asset_icon.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../../components/search_app_bar.dart';
import '../../../../dao/series_dao.dart';
import '../../../../models/anime.dart';
import '../../../../models/series.dart';
import '../../../../utils/delay_util.dart';
import '../../../../utils/log.dart';
import '../../../../values/values.dart';
import '../../../../widgets/common_scaffold_body.dart';
import '../detail/view.dart';
import 'logic.dart';

class SeriesManagePage extends StatefulWidget {
  const SeriesManagePage({this.animeId = -1, Key? key}) : super(key: key);
  final int animeId;

  @override
  State<SeriesManagePage> createState() => _SeriesManagePageState();
}

class _SeriesManagePageState extends State<SeriesManagePage> {
  late SeriesManageLogic logic;
  double get itemHeight => 240;
  double get maxItemWidth => 260;
  double get coverHeight => 160;
  bool get enableSelectSeriesForAnime => logic.enableSelectSeriesForAnime;

  bool searchAction = false;
  bool showRecommendedSeries =
      SPUtil.getBool(SPKey.showRecommendedSeries, defaultValue: true);

  SeriesStyle seriesStyle = SeriesStyle();

  // 该动漫已加入的系列
  List<Series> get addedSeriesList {
    if (!enableSelectSeriesForAnime) return [];

    List<Series> list = [];
    // 遍历所有系列
    for (var series in logic.seriesList) {
      // 如果系列中存在该动漫则添加
      if (series.animes
              .indexWhere((anime) => anime.animeId == widget.animeId) >=
          0) {
        list.add(series);
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    // 使用tag，避免系列管理页->->系列详细页->动漫详细页->系列页，因为已经创建过logic了，所以传入的animeId仍然是最初的-1
    // 很奇怪的是返回再进入系列页就正常了。更奇怪的是退出系列页时会删除logic，而返回到系列管理页时，logic仍能正常运行
    var tag = DateTime.now().toString();
    logic =
        Get.put(SeriesManageLogic(tag: tag, animeId: widget.animeId), tag: tag);
  }

  @override
  void dispose() {
    // 离开页面时销毁该logic，避免恢复数据时看到旧数据
    Get.delete<SeriesManageLogic>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return Scaffold(
      appBar: searchAction ? _buildSearchBar() : _buildCommonAppBar(),
      body: GetBuilder(
        init: logic,
        tag: logic.tag,
        builder: (_) => CommonScaffoldBody(
          child: RefreshIndicator(
            child: _buildSeriesBody(context),
            onRefresh: () async {
              await logic.getAllSeries();
            },
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  AppBar _buildCommonAppBar() {
    return AppBar(
      title: Text(enableSelectSeriesForAnime ? "系列" : "系列管理"),
      automaticallyImplyLeading: true,
      actions: [
        IconButton(
            onPressed: () {
              _showLayoutBottomSheet();
            },
            icon: const Icon(Icons.layers_outlined)),
        IconButton(
            onPressed: () {
              setState(() {
                searchAction = !searchAction;
              });
            },
            icon: const Icon(Icons.search))
      ],
    );
  }

  _showLayoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                onTap: () {
                  if (seriesStyle.useList) {
                    seriesStyle.enableGrid();
                  } else {
                    seriesStyle.enableList();
                  }
                  setState(() {});
                },
                title: Text("${seriesStyle.useList ? '列表' : '网格'}样式"),
                subtitle: const Text('切换列表/网格样式'),
              )
            ],
          ),
        ),
      ),
    );
  }

  _buildSeriesBody(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (enableSelectSeriesForAnime)
          const SliverToBoxAdapter(child: SettingTitle(title: '已加入')),
        if (enableSelectSeriesForAnime)
          _buildSeriesView(
            addedSeriesList,
            // 已加入是从全部系列中获取的，所以加载圈和加载全部共用一个
            loading: logic.loadingSeriesList,
          ),
        // 动漫详情页进入的系列页，推荐放在全部上方
        if (enableSelectSeriesForAnime)
          SliverToBoxAdapter(child: _buildAnimeRecommendTitle(context)),
        if (enableSelectSeriesForAnime && showRecommendedSeries)
          _buildSeriesView(logic.recommendSeriesList,
              loading: logic.loadingRecommendSeriesList),
        // 所有推荐不直接展示，通过点击后弹出底部面板
        // 从而避免点击推荐里的创建时，因全部GridView行数增多时，滚动位置变化
        if (!enableSelectSeriesForAnime && logic.recommendSeriesList.isNotEmpty)
          SliverToBoxAdapter(child: _buildAllRecommendTitle(context)),
        // 显示全部已创建的系列
        SliverToBoxAdapter(
            child: SettingTitle(title: '全部 (${logic.seriesList.length})')),
        _buildSeriesView(logic.seriesList, loading: logic.loadingSeriesList),
        // 避免紧挨底部
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  ListTile _buildCreateAllButton(BuildContext context) {
    return ListTile(
      title: Text(
        '创建全部',
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
      onTap: () async {
        ToastUtil.showLoading(
            msg: '创建中',
            task: () async {
              for (var series in logic.recommendSeriesList) {
                await SeriesDao.insert(series);
              }
              logic.getAllSeries();
              ToastUtil.showText('全部创建完毕');
            });
      },
    );
  }

  _buildAnimeRecommendTitle(BuildContext context) {
    return SettingTitle(
      title: '推荐',
      trailing: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          setState(() {
            showRecommendedSeries = !showRecommendedSeries;
          });
          SPUtil.setBool(SPKey.showRecommendedSeries, showRecommendedSeries);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            showRecommendedSeries ? '隐藏' : '显示',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  _buildAllRecommendTitle(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GetBuilder(
                  init: logic,
                  tag: logic.tag,
                  builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('推荐')),
                      body: CommonScaffoldBody(
                          child: CustomScrollView(
                        slivers: [
                          if (logic.recommendSeriesList.isNotEmpty)
                            SliverToBoxAdapter(
                                child: _buildCreateAllButton(context)),
                          _buildSeriesView(logic.recommendSeriesList),
                        ],
                      )))),
            ));
      },
      child: SettingTitle(
        title: '推荐 (${logic.recommendSeriesList.length})',
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  _buildSeriesView(
    List<Series> seriesList, {
    bool loading = false,
  }) {
    if (loading) {
      return const SliverToBoxAdapter(child: LoadingWidget());
    }

    if (seriesList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text('无'),
        ),
      );
    }

    if (seriesStyle.useList) {
      return SliverList.builder(
        itemCount: seriesList.length,
        itemBuilder: (context, index) {
          var series = seriesList[index];
          Anime? firstHasCoverAnime;
          for (var anime in series.animes) {
            if (anime.animeCoverUrl.isNotEmpty) {
              firstHasCoverAnime = anime;
              break;
            }
          }
          return ListTile(
            leading: firstHasCoverAnime == null
                ? const SizedBox(
                    height: 40,
                    width: 40,
                    child: Center(
                      child: SvgAssetIcon(
                          assetPath: Assets.iconsCollections24Regular),
                    ),
                  )
                : AnimeListCover(
                    firstHasCoverAnime,
                    showReviewNumber: false,
                  ),
            title:
                Text(series.name, overflow: TextOverflow.ellipsis, maxLines: 1),
            subtitle: Text('${series.animes.length}'),
            trailing: _buildActionButton(context, series),
            onTap: () =>
                _toSeriesDetailPage(context, series, seriesList, index),
            onLongPress: () => _showOpMenuDialog(context, series),
          );
        },
      );
    }

    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        mainAxisExtent: itemHeight,
        maxCrossAxisExtent: maxItemWidth,
      ),
      itemCount: seriesList.length,
      itemBuilder: (context, index) {
        return _buildSeriesGridItem(context, seriesList, index);
      },
    );
  }

  _buildSeriesGridItem(
      BuildContext context, List<Series> seriesList, int index) {
    var series = seriesList[index];
    return Card(
      child: InkWell(
        onTap: () => _toSeriesDetailPage(context, series, seriesList, index),
        onLongPress: () => _showOpMenuDialog(context, series),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverlayCover(series),
            _buildInfo(series, context),
          ],
        ),
      ),
    );
  }

  void _toSeriesDetailPage(
      BuildContext context, Series series, List<Series> seriesList, int index) {
    if (series.id == logic.recommendSeriesId) {
      return;
    }

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeriesDetailPage(series),
        )).then((value) async {
      // 更新该系列
      seriesList[index] = await SeriesDao.getSeriesById(series.id);
      logic.update();
    });
  }

  _buildMoreButton(BuildContext context, Series series) {
    var borderRadius = BorderRadius.circular(99);
    return InkWell(
        borderRadius: borderRadius,
        onTap: () {
          _showOpMenuDialog(context, series);
        },
        child: SizedBox(
          height: 30,
          width: 30,
          child: Center(
            child: Icon(
              Icons.more_horiz,
              size: 20,
              color: Theme.of(context).hintColor.withOpacity(0.4),
            ),
          ),
        ));
  }

  _buildInfo(Series series, BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(left: 8, top: 8, right: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              series.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                // overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
            Expanded(
              child: Row(
                children: [
                  if (series.id != logic.recommendSeriesId)
                    Text(
                      '${series.animes.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  const Spacer(),
                  _buildActionButton(context, series),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InkWell _buildActionButton(BuildContext context, Series series) {
    var isAdded = 'isAdded', // 动漫已加入该系列
        isCreated = 'isCreated', // 已创建该系列
        isNotCreated = 'isNotCreated'; // 为创建该系列
    String status;

    if (series.id == logic.recommendSeriesId) {
      status = isNotCreated;
    } else if (addedSeriesList
            .indexWhere((element) => element.id == series.id) >=
        0) {
      status = isAdded;
    } else {
      status = isCreated;
    }

    var color = status == isAdded
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).primaryColor;

    // 进入系列管理页时：推荐的系列显示创建按钮，已创建的系列显示更多按钮
    // 从动漫详情页中进入该页时：推荐的系列显示创建按钮，已创建的系列显示加入按钮，已加入的系列显示退出按钮
    if (!enableSelectSeriesForAnime && status == isCreated) {
      return _buildMoreButton(context, series);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: () async {
        var cancel = ToastUtil.showLoading(msg: "");
        if (status == isNotCreated) {
          // 创建该系列
          int newId = await SeriesDao.insert(series);
          if (enableSelectSeriesForAnime && newId > 0) {
            // 加入该系列
            await AnimeSeriesDao.insertAnimeSeries(widget.animeId, newId);
          }
        } else if (status == isAdded) {
          // 退出该系列
          await AnimeSeriesDao.deleteAnimeSeries(widget.animeId, series.id);
        } else if (status == isCreated) {
          // 加入该系列
          await AnimeSeriesDao.insertAnimeSeries(widget.animeId, series.id);
        }
        await logic.getAllSeries();
        cancel();
      },
      onLongPress: () {
        // 避免触发背景卡片长按弹出对话框
      },
      child: Container(
        decoration: BoxDecoration(
          // color:color,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(99),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Text(
          status == isNotCreated && enableSelectSeriesForAnime
              ? '创建并加入'
              : status == isNotCreated
                  ? '创建'
                  : status == isAdded
                      ? '退出'
                      : '加入',
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
          // style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  _buildOverlayCover(Series series) {
    var imgCnt =
        // min(4, series.animes.length);
        series.animes.length;

    return SizedBox(
      height: coverHeight,
      child: imgCnt == 0
          ? Center(
              child: SvgAssetIcon(
                assetPath: Assets.iconsCollections24Regular,
                size: coverHeight / 3,
                color: Theme.of(context).hintColor.withOpacity(0.2),
              ),
            )
          : imgCnt == 1
              ? SizedBox(
                  width: maxItemWidth,
                  child: CommonImage(series.animes.first.animeCoverUrl))
              : ListView.builder(
                  itemCount: imgCnt,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => Container(
                      padding: const EdgeInsets.only(right: 2),
                      color: Theme.of(context).cardColor,
                      child: CommonImage(series.animes[index].animeCoverUrl)),
                ),
    );
  }

  _buildSearchBar() {
    return SearchAppBar(
      isAppBar: true,
      autofocus: true,
      useModernStyle: false,
      showCancelButton: true,
      inputController: logic.inputKeywordController,
      hintText: "搜索系列",
      onChanged: (kw) async {
        Log.info("搜索系列关键字：$kw");
        // 必须要查询数据库，而不是从已查询的全部数据中删除不含关键字的记录，否则会越删越少
        DelayUtil.delaySearch(() async {
          logic.seriesList = await SeriesDao.searchSeries(kw);
          logic.kw = kw; // 记录关键字
          logic.update();
        });
      },
      onEditingComplete: () {
        logic.kw = logic.inputKeywordController.text;
      },
      onTapClear: () async {
        logic.inputKeywordController.clear();
        logic.kw = "";
        logic.getAllSeries();
      },
      onTapCancelButton: () {
        logic.inputKeywordController.clear();
        logic.kw = "";
        // 重新搜索所有系列
        logic.getAllSeries();
        setState(() {
          searchAction = false;
        });
      },
    );
  }

  _showOpMenuDialog(
    BuildContext context,
    Series series,
  ) {
    if (series.id == logic.recommendSeriesId) {
      return;
    }

    showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              children: [
                ListTile(
                  title: const Text("编辑"),
                  leading: const Icon(Icons.edit),
                  onTap: () {
                    Log.info("编辑系列：$series");
                    Navigator.of(context).pop();

                    int index = logic.seriesList
                        .indexWhere((element) => element == series);
                    _toModifySeriesFormPage(context, index);
                  },
                ),
                ListTile(
                  title: const Text("删除"),
                  leading: const Icon(Icons.delete_outline),
                  onTap: () {
                    Log.info("删除系列：$series");
                    Navigator.of(context).pop();
                    _showDialogConfirmDelete(context, series);
                  },
                )
              ],
            ));
  }

  _showDialogConfirmDelete(BuildContext context, Series series) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("确定删除吗？"),
              content: Text("将要删除的系列：${series.name}"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("取消")),
                TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await SeriesDao.delete(series.id);

                      if (searchAction) {
                        // 重新搜索
                        logic.seriesList = await SeriesDao.searchSeries(
                            logic.inputKeywordController.text);
                        logic.update();
                      } else {
                        // 重新获取，是为了方便重新生成推荐，例如详情页退出某个系列后，在推荐里能继续看到
                        logic.getAllSeries();
                      }
                    },
                    child: Text(
                      "删除",
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    )),
              ],
            ));
  }

  _buildFloatingActionButton(
    BuildContext context,
  ) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SeriesFormPage(),
            )).then((value) {
          logic.getAllSeries();
        });
      },
      child: const Icon(MingCuteIcons.mgc_add_line),
    );
  }

  _toModifySeriesFormPage(BuildContext context, int index) {
    Series series = logic.seriesList[index];
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeriesFormPage(
            series: series,
          ),
        )).then((value) {
      logic.update();
    });
  }
}