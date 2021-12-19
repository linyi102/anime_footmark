import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/pages/anime_list_page.dart';
import 'package:flutter_test_future/pages/history_page.dart';
import 'package:flutter_test_future/pages/setting_page.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:search_page/search_page.dart';

late List<Anime> animes;

class Tabs extends StatefulWidget {
  const Tabs({Key? key}) : super(key: key);

  @override
  _TabsState createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  final List<Widget> _list = [
    const AnimeListPage(),
    const HistoryPage(),
    const SettingPage(),
  ];
  final List _listName = ["书架", "历史", "更多"];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<List<Widget>> actions = [];
    for (int i = 0; i < _listName.length; ++i) {
      // error: actions[i] = []; 因为最外面的List为空，需要添加元素：空的List
      actions.add([]);
    }
    actions[0].add(
      IconButton(
        onPressed: () => showSearch(
          context: context,
          delegate: SearchPage<Anime>(
            items: animes,
            searchLabel: "  Search",
            builder: (anime) => AnimeItem(anime),
            failure: const Center(
              child: Text('No anime found :('),
            ),
            filter: (anime) => [
              anime.animeName,
            ],
          ),
        ),
        icon: const Icon(Icons.search_outlined),
        color: Colors.black,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _listName[_currentIndex],
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        shadowColor: Colors.transparent,
        backgroundColor: Colors.white,
        actions: actions[_currentIndex],
      ),
      // body: _list[_currentIndex], // 原始方法
      body: IndexedStack(
        // 新方法，可以保持页面状态
        index: _currentIndex,
        children: _list,
      ),
      // bottomNavigationBar: SalomonBottomBar(
      //   currentIndex: _currentIndex,
      //   onTap: (int index) {
      //     setState(() => _currentIndex = index);
      //   },
      //   items: [
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.book), title: const Text("书架")),
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.history_rounded), title: const Text("历史")),
      //     SalomonBottomBarItem(
      //         icon: const Icon(Icons.more_horiz), title: const Text("更多")),
      //   ],
      // ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color.fromRGBO(254, 254, 254, 1),
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "书架",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "历史",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "更多",
          ),
        ],
      ),
    );
  }
}
