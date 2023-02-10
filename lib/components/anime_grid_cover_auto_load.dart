import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_grid_cover.dart';
import 'package:flutter_test_future/components/fade_animated_switcher.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/anime_detail.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';

/// 自动根据动漫详细地址来获取封面
class AnimeGridCoverAutoLoad extends StatefulWidget {
  const AnimeGridCoverAutoLoad({required this.anime, super.key});
  final Anime anime;

  @override
  State<AnimeGridCoverAutoLoad> createState() => _AnimeGridCoverAutoLoadState();
}

class _AnimeGridCoverAutoLoadState extends State<AnimeGridCoverAutoLoad> {
  late Anime anime;
  late bool loading;

  @override
  void initState() {
    super.initState();
    anime = widget.anime;

    // 如果没有收藏，则从数据库中根据动漫链接查询是否已添加
    // 在查询过程中显示加载圈，不允许进入详情页
    // 如果数据库中没有，则根据动漫链接爬取动漫信息
    if (anime.isCollected()) {
      loading = false;
    } else {
      _load();
    }

    // if (anime.animeCoverUrl.isEmpty) {
    //   loadingCover = true;
    //   _loadCover();
    // } else {
    //   if (mounted) {
    //     setState(() {
    //       loadingCover = false;
    //     });
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return AnimeGridCover(
      anime,
      onPressed: () {
        // 一定要在内部进入详情页，因为widget.anime和这里的anime不一样，这里的anime是最新的
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailPlus(anime),
          ),
        );
      },
      loading: loading,
      showProgress: anime.isCollected() ? true : false,
      showReviewNumber: anime.isCollected() ? true : false,
    );
  }

  void _load() async {
    // 加载中
    setState(() {
      loading = true;
    });

    Anime dbAnime = await SqliteUtil.getAnimeByAnimeUrl(anime);
    if (dbAnime.isCollected()) {
      // 数据库中找到了
      anime = dbAnime;
    } else {
      // 数据库中没有找到，则爬取信息
      // 如果之前爬取过信息，就不再爬取了
      if (!anime.climbFinished) {
        anime = await ClimbAnimeUtil.climbAnimeInfoByUrl(widget.anime,
            showMessage: false);
        anime.climbFinished = true;
      }
    }

    // 加载完毕
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}
