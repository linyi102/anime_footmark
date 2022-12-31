import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';

class Anime {
  int animeId;
  String animeName;
  int animeEpisodeCnt;
  String tagName;
  String animeDesc;
  String animeCoverUrl;
  int rate;

  int checkedEpisodeCnt;
  int reviewNumber;
  String animeUrl; // 动漫网址

  String premiereTime;
  String nameAnother;
  String nameOri;
  String authorOri;
  String area;
  String category;
  String playStatus;
  String productionCompany;
  String officialSite;

  Anime(
      {this.animeId = 0,
      required this.animeName,
      this.animeEpisodeCnt = 0,
      this.tagName = "",
      this.animeCoverUrl = "",
      this.checkedEpisodeCnt = 0,
      this.animeDesc = "",
      this.reviewNumber = 1,
      this.animeUrl = "",
      this.premiereTime = "",
      this.nameAnother = "",
      this.nameOri = "",
      this.authorOri = "",
      this.area = "",
      this.category = "",
      this.playStatus = "",
      this.productionCompany = "",
      this.officialSite = "",
      this.rate = 0});

  @override
  String toString() {
    return "Anime=[animeId=$animeId, animeName=$animeName, "
        "animeEpisodeCnt=$animeEpisodeCnt, tagName=$tagName, "
        "checkedEpisodeCnt=$checkedEpisodeCnt, animeCoverUrl=$animeCoverUrl, "
        "animeUrl=$animeUrl, premiereTime=$premiereTime, "
        "animeDesc=${reduceStr(animeDesc)}, playStatus=$playStatus, "
        "category=$category, area=$area, rate=$rate]";
  }

  String reduceStr(String str) {
    return str.length > 15 ? str.substring(0, 15) : str;
  }

  String getAnimeInfoFirstLine() {
    var list = [];
    if (area.isNotEmpty) {
      list.add(area);
    }
    if (category.isNotEmpty) {
      list.add(category);
    }
    if (premiereTime.isNotEmpty) {
      list.add(premiereTime);
    }

    return list.join(" / ");
  }

  String getAnimeSource() {
    return ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(animeUrl)?.name ?? "自定义";
  }

  String getPlayStatus() {
    if (playStatus.contains("完结")) {
      return "已完结";
    } else if (playStatus.contains("未")) {
      return "未开播";
    } else if (playStatus.contains("第") || playStatus.contains("连载")) {
      return "连载中";
    } else {
      return "未知";
    }
  }

  String getAnimeInfoSecondLine() {
    var list = [];
    list.add(getAnimeSource());
    list.add(getPlayStatus());
    if (animeEpisodeCnt != -1) {
      list.add("$animeEpisodeCnt 集");
    }
    return list.join(" • ");
  }

  bool isCollected() {
    return animeId > 0;
    // return tagName.isNotEmpty;
  }

  Anime copyWith({
    int? animeId,
    String? animeName,
    int? animeEpisodeCnt,
    String? tagName,
    String? animeDesc,
    String? animeCoverUrl,
    int? rate,
    int? checkedEpisodeCnt,
    int? reviewNumber,
    String? animeUrl,
    String? premiereTime,
    String? nameAnother,
    String? nameOri,
    String? authorOri,
    String? area,
    String? category,
    String? playStatus,
    String? productionCompany,
    String? officialSite,
  }) {
    return Anime(
      animeId: animeId ?? this.animeId,
      animeName: animeName ?? this.animeName,
      animeEpisodeCnt: animeEpisodeCnt ?? this.animeEpisodeCnt,
      tagName: tagName ?? this.tagName,
      animeDesc: animeDesc ?? this.animeDesc,
      animeCoverUrl: animeCoverUrl ?? this.animeCoverUrl,
      rate: rate ?? this.rate,
      checkedEpisodeCnt: checkedEpisodeCnt ?? this.checkedEpisodeCnt,
      reviewNumber: reviewNumber ?? this.reviewNumber,
      animeUrl: animeUrl ?? this.animeUrl,
      premiereTime: premiereTime ?? this.premiereTime,
      nameAnother: nameAnother ?? this.nameAnother,
      nameOri: nameOri ?? this.nameOri,
      authorOri: authorOri ?? this.authorOri,
      area: area ?? this.area,
      category: category ?? this.category,
      playStatus: playStatus ?? this.playStatus,
      productionCompany: productionCompany ?? this.productionCompany,
      officialSite: officialSite ?? this.officialSite,
    );
  }
}
