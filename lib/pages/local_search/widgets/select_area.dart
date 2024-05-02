import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/enum/anime_area.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:get/get.dart';

class SelectAreaView extends StatefulWidget {
  const SelectAreaView({required this.localSearchController, super.key});
  final LocalSearchController localSearchController;

  @override
  State<SelectAreaView> createState() => _SelectAreaViewState();
}

class _SelectAreaViewState extends State<SelectAreaView> {
  LocalSelectFilter get localSelectFilter =>
      widget.localSearchController.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.localSearchController,
      builder: (_) => Scaffold(
        body: ListView.builder(
          itemCount: AnimeArea.values.length,
          itemBuilder: (context, index) {
            final area = AnimeArea.values[index];
            return RadioListTile<AnimeArea>(
                title: Text(area.label),
                toggleable: true,
                value: area,
                groupValue: localSelectFilter.area,
                onChanged: (value) {
                  widget.localSearchController.setArea(value);
                });
          },
        ),
      ),
    );
  }
}
