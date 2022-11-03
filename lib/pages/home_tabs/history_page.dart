import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/models/history_plus.dart';
import 'package:flutter_test_future/models/anime_history_record.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Map<int, List<HistoryPlus>> yearHistory = {};
  Map<int, bool> yearLoadOk = {};
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();

    _loadData(selectedYear);
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    //为了避免内存泄露，需要调用.dispose
    _scrollController.dispose();
    super.dispose();
  }

  _loadData(int year) async {
    debugPrint("加载$year年数据中...");
    Future(() {
      return SqliteUtil.getAllHistoryByYear(year);
    }).then((value) {
      debugPrint("$year年数据加载完成");
      yearHistory[year] = value;
      yearLoadOk[year] = true;
      setState(() {});
    });
  }

  int minYear = 1970, maxYear = DateTime.now().year + 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              const Text("历史", style: TextStyle(fontWeight: FontWeight.w600))),
      body: RefreshIndicator(
          // 下拉刷新
          onRefresh: () async => _loadData(selectedYear),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !yearLoadOk.containsKey(selectedYear)
                ? loadingWidget(context)
                : _buildHistory(),
          )),
    );
  }

  _formatDate(String date) {
    return date.replaceAll("-", "/");
  }

  Widget _buildHistory() {
    return Stack(children: [
      Column(
        children: [
          _buildOpYearButton(),
          yearHistory[selectedYear]!.isEmpty
              ? Expanded(child: emptyDataHint("什么都没有"))
              : Expanded(
                  child: Scrollbar(
                      controller: _scrollController,
                      child: (
                          // ListView.separated(
                          ListView.builder(
                        controller: _scrollController,
                        itemCount: yearHistory[selectedYear]!.length,
                        itemBuilder: (BuildContext context, int index) {
                          // debugPrint("$index");
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Card(
                              elevation: 0,
                              child: Column(
                                children: [
                                  //显示日期
                                  ListTile(
                                    title: Text(
                                        _formatDate(
                                            yearHistory[selectedYear]![index]
                                                .date),
                                        textScaleFactor:
                                            ThemeUtil.smallScaleFactor),
                                  ),
                                  Column(children: _buildRecords(index)),
                                  // 避免最后一项太靠近卡片底部，因为标题没有紧靠顶部，所以会导致不美观
                                  const SizedBox(height: 5)
                                ],
                              ),
                            ),
                          );
                        },
                      ))),
                ),
        ],
      ),
    ]);
  }

  List<Widget> _buildRecords(int index) {
    List<Widget> listWidget = [];
    List<AnimeHistoryRecord> records =
        yearHistory[selectedYear]![index].records;
    for (var record in records) {
      listWidget.add(
        ListTile(
          title: Text(
            record.anime.animeName,
            overflow: TextOverflow.ellipsis,
            // textScaleFactor: ThemeUtil.smallScaleFactor,
          ),
          leading: AnimeListCover(record.anime,
              showReviewNumber: true, reviewNumber: record.reviewNumber),
          subtitle: Text(
              (record.startEpisodeNumber == record.endEpisodeNumber
                  ? record.startEpisodeNumber.toString()
                  : "${record.startEpisodeNumber}~${record.endEpisodeNumber}"),
              textScaleFactor: ThemeUtil.tinyScaleFactor),
          // trailing: Transform.scale(
          //   scale: 0.8,
          //   child: Chip(
          //       label: Text(
          //           (record.startEpisodeNumber == record.endEpisodeNumber
          //               ? record.startEpisodeNumber.toString()
          //               : "${record.startEpisodeNumber}~${record.endEpisodeNumber}"),
          //           textScaleFactor: ThemeUtil.smallScaleFactor)),
          // ),
          onTap: () {
            Navigator.of(context)
                .push(
              // MaterialPageRoute(
              //   builder: (context) => AnimeDetailPlus(record.anime.animeId),
              // ),
              FadeRoute(
                transitionDuration: const Duration(milliseconds: 200),
                builder: (context) {
                  return AnimeDetailPlus(record.anime);
                },
              ),
            )
                .then((value) {
              _loadData(selectedYear);
            });
          },
        ),
      );
    }
    return listWidget;
  }

  Widget _buildOpYearButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: () {
                      if (selectedYear - 1 < minYear) {
                        return;
                      }
                      selectedYear--;
                      // 没有加载过，才去查询数据库
                      if (!yearLoadOk.containsKey(selectedYear)) {
                        debugPrint("之前未查询过$selectedYear年，现查询");
                        _loadData(selectedYear);
                      } else {
                        // 加载过，直接更新状态
                        debugPrint("查询过$selectedYear年，直接更新状态");
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.arrow_left_rounded)),
                GestureDetector(
                  child: Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text("$selectedYear",
                        textScaleFactor: 1.2,
                        style: TextStyle(
                            // fontWeight: FontWeight.w600,
                            color: ThemeUtil.getFontColor())),
                  ),
                  onTap: () {
                    dialogSelectUint(context, "选择年份",
                            initialValue: selectedYear,
                            minValue: minYear,
                            maxValue: maxYear)
                        .then((value) {
                      if (value == null) {
                        debugPrint("未选择，直接返回");
                        return;
                      }
                      debugPrint("选择了$value");
                      selectedYear = value;
                      _loadData(selectedYear);
                    });
                  },
                ),
                IconButton(
                    onPressed: () {
                      if (selectedYear + 1 > maxYear) {
                        showToast("前面的区域，以后再来探索吧！");
                        return;
                      }
                      selectedYear++;
                      // 没有加载过，才去查询数据库
                      if (!yearLoadOk.containsKey(selectedYear)) {
                        debugPrint("之前未查询过$selectedYear年，现查询");
                        _loadData(selectedYear);
                      } else {
                        // 加载过，直接更新状态
                        debugPrint("查询过$selectedYear年，直接更新状态");
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.arrow_right_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
