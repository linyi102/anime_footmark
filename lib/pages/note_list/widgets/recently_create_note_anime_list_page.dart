import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_list_tile.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/dao/episode_note_dao.dart';
import 'package:flutter_test_future/models/anime.dart';

class RecentlyCreateNoteAnimeListPage extends StatefulWidget {
  const RecentlyCreateNoteAnimeListPage(
      {super.key, this.selectedAnime, this.onTapItem});
  final Anime? selectedAnime;
  final void Function(Anime? anime)? onTapItem;

  @override
  State<RecentlyCreateNoteAnimeListPage> createState() =>
      _RecentlyCreateNoteAnimeListPageState();
}

class _RecentlyCreateNoteAnimeListPageState
    extends State<RecentlyCreateNoteAnimeListPage> {
  List<Anime> recentlyCreateNoteAnimes = [];
  bool loadOk = false;

  @override
  void initState() {
    super.initState();
    _loadRecentlyCreatNoteAnime();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: loadOk
          ? ListView.builder(
              itemCount: recentlyCreateNoteAnimes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAnimeItemCard(
                    child: const ListTile(title: Text('全部笔记')),
                    isSelected: widget.selectedAnime == null,
                  );
                }

                final animeIndex = index - 1;
                final anime = recentlyCreateNoteAnimes[animeIndex];
                return _buildAnimeItemCard(
                    child: AnimeListTile(anime: anime),
                    anime: anime,
                    isSelected: anime == widget.selectedAnime);
              },
            )
          : const LoadingWidget(),
    );
  }

  Container _buildAnimeItemCard({
    required Widget child,
    bool isSelected = false,
    Anime? anime,
  }) {
    var radius = BorderRadius.circular(6);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 15, 0),
      decoration: BoxDecoration(
        borderRadius: radius,
        color:
            isSelected ? Theme.of(context).hintColor.withOpacity(0.08) : null,
      ),
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        borderRadius: radius,
        onTap: () {
          widget.onTapItem?.call(anime);
        },
        child: child,
      ),
    );
  }

  _loadRecentlyCreatNoteAnime() async {
    recentlyCreateNoteAnimes =
        await EpisodeNoteDao.getAnimesRecentlyCreateNote();
    loadOk = true;
    if (mounted) setState(() {});
  }
}
