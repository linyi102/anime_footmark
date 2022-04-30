import 'package:dio/dio.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/filter.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:html/parser.dart';
import 'package:flutter/material.dart';

class ClimbAnimeUtil {
  // 全局刷新动漫封面
  static Future<String> climbCoverUrl(String keyword) async {
    String coverUrl = "";
    coverUrl = await sourceOfyhdm(keyword);

    return coverUrl;
  }

  static Future<String> sourceOfyhdm(String keyword) async {
    String url = "https://www.yhdmp.cc/s_all?ex=1&kw=$keyword";
    try {
      var response = await Dio().get(url);
      var document = parse(response.data);
      var elements = document.getElementsByClassName("lpic");
      String? coverUrl = elements[0]
          .children[0]
          .children[
              0] // 可能并没有元素，因此会提示：RangeError (index): Invalid value: Valid value range is empty: 0
          .children[0]
          .children[0]
          .attributes["src"];
      if (coverUrl != null && coverUrl.startsWith("//")) {
        coverUrl = "https:$coverUrl";
      }
      return coverUrl ?? ""; // 搜不到则返回空串
    } catch (e) {
      debugPrint(e.toString());
      return "";
    }
  }

  // 根据网址前缀来判断来源
  static String getSourceByAnimeUrl(String animeUrl) {
    if (animeUrl.isEmpty) {
      return "无来源";
    } else if (animeUrl.startsWith("https://www.yhdmp.cc")) {
      return "樱花动漫";
    } else if (animeUrl.startsWith("https://omofun.tv/")) {
      return "OmoFun";
    } else {
      return "未知来源";
    }
  }

  // 根据过滤查询目录动漫
  static Future<List<Anime>> climbDirectory(Filter filter) async {
    List<Anime> directory = [];
    String selectedWebsite =
        SPUtil.getString("selectedWebsite", defaultValue: "樱花动漫");
    if (selectedWebsite == "樱花动漫") {
      directory = await _climbDirectoryOfyhdm(filter);
    } else if (selectedWebsite == "OmoFun") {
      // directory = await climbDirectoryOfOmoFun(filter);
    } else {
      throw ("爬取的网站名错误: $selectedWebsite");
    }
    return directory;
  }

  static Future<List<Anime>> _climbDirectoryOfyhdm(Filter filter) async {
    String baseUrl = "https://www.yhdmp.cc";
    String url = baseUrl +
        "/list/?region=${filter.region}&year=${filter.year}&season=${filter.season}&status=${filter.status}&label=${filter.label}&order=${filter.order}&genre=${filter.category}";

    List<Anime> directory = await _climbOfyhdm(baseUrl, url);
    return directory;
  }

  // 目录页和搜索页的结果一致，只是链接不一样，共用爬取片段
  static Future<List<Anime>> _climbOfyhdm(String baseUrl, String url) async {
    List<Anime> animes = [];
    try {
      var response = await Dio().get(url);
      var document = parse(response.data);
      var lpic = document.getElementsByClassName("lpic")[0];
      var lis = lpic.getElementsByTagName("li");
      for (var li in lis) {
        String desc = li.getElementsByTagName("p")[0].innerHtml;
        String episodeCntStr = li.getElementsByTagName("font")[0].innerHtml;
        int episodeCnt = _parseEpisodeCntOfyhdm(episodeCntStr);

        String? coverUrl = li.getElementsByTagName("img")[0].attributes["src"];
        if (coverUrl != null && coverUrl.startsWith("//")) {
          coverUrl = "https:$coverUrl";
        }
        String? animeName = li.getElementsByTagName("img")[0].attributes["alt"];
        String animeUrl = baseUrl +
            (li.getElementsByTagName("a")[0].attributes["href"] ?? "");
        Anime anime = Anime(
          animeName: animeName ?? "", // 没有名字时返回空串
          animeEpisodeCnt: episodeCnt,
          animeDesc: desc,
          animeCoverUrl: coverUrl ?? "",
          animeUrl: animeUrl,
        );
        animes.add(anime);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return animes;
  }

  // 解析樱花动漫里的集数
  static int _parseEpisodeCntOfyhdm(String episodeCntStr) {
    int episodeCnt = 0;
    if (episodeCntStr.contains("[全集]")) {
      episodeCnt = 1;
    } else if (episodeCntStr.contains("第")) {
      // 例如：第13集(完结)
      int episodeCntStartIndex = episodeCntStr.indexOf("第") + 1;
      int episodeCntEndIndex = episodeCntStr.indexOf("集");
      if (episodeCntStartIndex < episodeCntEndIndex) {
        episodeCnt = int.parse(
            episodeCntStr.substring(episodeCntStartIndex, episodeCntEndIndex));
      }
    } else if (episodeCntStr.contains("01-")) {
      // 例如：[TV 01-12+OVA+SP]
      int episodeCntStartIndex = episodeCntStr.indexOf("01-") + 3; // 跳过01-
      // [start, end)，中间有2个数字，即集数
      episodeCnt = int.parse(episodeCntStr.substring(
          episodeCntStartIndex, episodeCntStartIndex + 2));
    }
    return episodeCnt;
  }

  // 根据关键字爬取动漫
  static Future<List<Anime>> climbAnimesByKeyword(String keyword) async {
    List<Anime> allAnimeNameAndCoverUrl = [];

    String selectedWebsite =
        SPUtil.getString("selectedWebsite", defaultValue: "樱花动漫");
    if (selectedWebsite == "樱花动漫") {
      allAnimeNameAndCoverUrl = await _climbAnimesByKeywordOfyhdm(keyword);
    } else if (selectedWebsite == "OmoFun") {
      allAnimeNameAndCoverUrl = await _climbAnimesByKeywordOfOmoFun(keyword);
    } else {
      throw ("爬取的网站名错误: $selectedWebsite");
    }
    return allAnimeNameAndCoverUrl;
  }

  static Future<List<Anime>> _climbAnimesByKeywordOfyhdm(String keyword) async {
    String baseUrl = "https://www.yhdmp.cc";
    String url = baseUrl + "/s_all?ex=1&kw=$keyword";
    return await _climbOfyhdm(baseUrl, url);
  }

  static Future<List<Anime>> _climbAnimesByKeywordOfOmoFun(
      String keyword) async {
    String baseUrl = "https://omofun.tv";
    String url = baseUrl + "/index.php/vod/search.html?wd=$keyword";
    List<Anime> climbAnimes = [];
    try {
      debugPrint("正在获取文档...");
      var response = await Dio().get(url);
      var document = parse(response.data);
      debugPrint("获取文档成功√，正在解析...");

      // 速度慢在了获取文档中，解析速度很快，可能是因为有数据结构
      // var elements = document
      //     .getElementsByTagName("body")[0]
      //     .getElementsByClassName("main")[0]
      //     .getElementsByClassName("content")[0]
      //     .getElementsByClassName("module")[0]
      //     .getElementsByClassName("module-main module-page")[0]
      //     .getElementsByClassName("lazy lazyload");

      var elements = document.getElementsByClassName("lazy lazyload");

      for (var element in elements) {
        String? coverUrl = element.attributes["data-original"];
        String? animeName = element.attributes["alt"];
        if (coverUrl != null) {
          if (coverUrl.startsWith("//")) coverUrl = "https:$coverUrl";
          climbAnimes.add(Anime(
              animeName: animeName ?? "", // 没有名字时返回空串
              animeEpisodeCnt: 0,
              animeCoverUrl: coverUrl));
          debugPrint("爬取封面：$coverUrl");
        }
      }
      // 爬取信息
      var elementsInfo =
          document.getElementsByClassName("module-card-item-info");
      for (int i = 0; i < elementsInfo.length; ++i) {
        String? animeUrl =
            elementsInfo[i].getElementsByTagName("a")[0].attributes["href"];
        climbAnimes[i].animeUrl = animeUrl == null ? "" : (baseUrl + animeUrl);
        debugPrint("爬取动漫网址：${climbAnimes[i].animeUrl}");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    debugPrint("解析完毕√");
    return climbAnimes;
  }

  // 进入该动漫网址，获取详细信息
  static Future<Anime> climbAnimeInfoByUrl(Anime anime) async {
    // 注意不要修改旧对象的id
    if (getSourceByAnimeUrl(anime.animeUrl) == "樱花动漫") {
      anime = await _climbAnimeInfoOfyhdm(anime);
      return anime;
    } else if (getSourceByAnimeUrl(anime.animeUrl) == "OmoFun") {
      anime = await _climbAnimeInfoOfOmoFun(anime);
    } else {
      debugPrint("无来源，无法更新，返回旧动漫对象");
    }
    return anime;
  }

  static Future<Anime> _climbAnimeInfoOfyhdm(Anime anime) async {
    try {
      var response = await Dio().get(anime.animeUrl);
      var document = parse(response.data);
      var animeInfo = document.getElementsByClassName("sinfo")[0];
      String str = animeInfo.getElementsByTagName("p")[0].innerHtml;
      // str内容：
      // <label>别名:</label>古見さんは、コミ ュ症です。2期
      debugPrint("str=$str");
      anime.nameAnother = str.substring(str.lastIndexOf(">") + 1); // +1跳过找的>

      // 获取首播时间
      // <a href="/list/?year=2020" target="_blank">2020</a>-01-11
      // <a href="/list/?year=2022" target="_blank">2022</a>-10
      // <a href="/list/?year=2022" target="_blank">2022</a>
      var element = animeInfo.getElementsByTagName("span")[0];
      str = element.innerHtml.trimRight(); // 需要去除右边的空白符
      String destStr = "target=\"_blank\">";
      // 从字符串中找到target="_blank">并跳过该子串，取后面所有子串
      anime.premiereTime =
          str.substring(str.lastIndexOf(destStr) + destStr.length);
      // 然后删除其中的</a>
      anime.premiereTime = anime.premiereTime.replaceAll("</a>", "");

      // 获取其他信息
      anime.area = animeInfo
          .getElementsByTagName("span")[1]
          .getElementsByTagName("a")[0]
          .innerHtml;
      anime.category = animeInfo
          .getElementsByTagName("span")[4]
          .getElementsByTagName("a")[0]
          .innerHtml;
      anime.playStatus = animeInfo
          .getElementsByTagName("span")[4]
          .getElementsByTagName("a")[2]
          .innerHtml;
      // 获取集数
      String episodeCntStr = animeInfo.getElementsByTagName("p")[1].innerHtml;
      anime.animeEpisodeCnt = _parseEpisodeCntOfyhdm(episodeCntStr);
    } catch (e) {
      debugPrint(e.toString());
    }
    debugPrint(anime.toString());
    return anime;
  }

  static Future<Anime> _climbAnimeInfoOfOmoFun(Anime anime) async {
    try {
      debugPrint("正在获取文档...");
      var response = await Dio().get(anime.animeUrl);
      var document = parse(response.data);
      debugPrint("获取文档成功√，正在解析...");
      int episodeCnt = 0;

      anime.animeEpisodeCnt =
          int.parse(document.getElementsByTagName("small")[0].innerHtml);
      anime.playStatus = document
          .getElementsByClassName("module-info-item-content")[3]
          .innerHtml;
      anime.premiereTime = document
          .getElementsByClassName("module-info-tag-link")[0]
          .getElementsByTagName("a")[0]
          .innerHtml;
      anime.area = document
          .getElementsByClassName("module-info-tag-link")[1]
          .getElementsByTagName("a")[0]
          .innerHtml;
      debugPrint("解析完毕√");
    } catch (e) {
      debugPrint(e.toString());
    }
    debugPrint(anime.toString());
    return anime;
  }
}
