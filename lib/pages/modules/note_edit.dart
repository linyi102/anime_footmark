import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/img_widget.dart';
import 'package:flutter_test_future/components/note_img_item.dart';
import 'package:flutter_test_future/dao/image_dao.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../../dao/note_dao.dart';
import '../../responsive.dart';
import '../../utils/theme_util.dart';

class NoteEdit extends StatefulWidget {
  final Note note; // 可能会修改笔记内容，因此不能用final
  const NoteEdit(this.note, {Key? key}) : super(key: key);

  @override
  State<NoteEdit> createState() => _NoteEditState();
}

class _NoteEditState extends State<NoteEdit> {
  bool _loadOk = false;
  bool _updateNoteContent = false; // 如果文本内容发生变化，返回时会更新数据库
  var noteContentController = TextEditingController();
  // Map<int, int> initialOrderIdx = {}; // key-value对应imageId-orderIdx

  @override
  void initState() {
    super.initState();
    noteContentController.text = widget.note.noteContent;
    debugPrint("进入笔记${widget.note.episodeNoteId}");
    _loadData();
  }

  _loadData() async {
    Future(() {
      return NoteDao.existNoteId(widget.note.episodeNoteId);
    }).then((existNoteId) {
      if (!existNoteId) {
        // 笔记id置0，从笔记编辑页返回到笔记列表页，接收到后根据动漫id删除所有相关笔记
        widget.note.episodeNoteId = 0;
        Navigator.of(context).pop(widget.note);
        showToast("未找到该笔记");
      }
      setState(() {
        _loadOk = true;
      });
      // // 记录所有图片的初始下标
      // for (int i = 0; i < widget.note.relativeLocalImages.length; ++i) {
      //   initialOrderIdx[widget.note.relativeLocalImages[i].imageId] = i;
      // }
    });
  }

  _onWillpop() async {
    Navigator.pop(context, widget.note);

    // 后台更新数据库中的图片顺序
    for (int newOrderIdx = 0;
        newOrderIdx < widget.note.relativeLocalImages.length;
        ++newOrderIdx) {
      int imageId = widget.note.relativeLocalImages[newOrderIdx].imageId;
      // 全部
      ImageDao.updateImageOrderIdxById(imageId, newOrderIdx);
      // 有缺陷，详细参考getRelativeLocalImgsByNoteId方法
      // if (initialOrderIdx[imageId] != newOrderIdx) {
      //   ImageDao.updateImageOrderIdxById(imageId, newOrderIdx);
      // }
    }
    if (_updateNoteContent) {
      NoteDao.updateEpisodeNoteContentByNoteId(
          widget.note.episodeNoteId, widget.note.noteContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 返回键
        _onWillpop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          // title: const Text("笔记编辑"),
          leading: IconButton(
              // 返回按钮
              onPressed: () {
                _onWillpop();
              },
              tooltip: "返回上一级",
              icon: const Icon(Icons.arrow_back_rounded)),
        ),
        body: _loadOk ? _buildBody() : Container(),
      ),
    );
  }

  _buildBody() {
    return Scrollbar(
      child: ListView(
        children: [
          widget.note.episode.number == 0
              ? Container() // 若为0，表明是评价，不显示该行
              : ListTile(
                  style: ListTileStyle.drawer,
                  leading: AnimeListCover(widget.note.anime),
                  title: Text(
                    widget.note.anime.animeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaleFactor: ThemeUtil.smallScaleFactor,
                  ),
                  subtitle: Text(
                    "第 ${widget.note.episode.number} 集 ${widget.note.episode.getDate()}",
                    textScaleFactor: ThemeUtil.tinyScaleFactor,
                  ),
                ),
          _showNoteContent(),
          Responsive(
              mobile: _buildReorderNoteImgGridView(crossAxisCount: 3),
              tablet: _buildReorderNoteImgGridView(crossAxisCount: 5),
              desktop: _buildReorderNoteImgGridView(crossAxisCount: 7))
        ],
      ),
    );
  }

  _showNoteContent() {
    return TextField(
      controller: noteContentController..text,
      decoration: const InputDecoration(
        hintText: "描述",
        border: InputBorder.none,
        contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 15),
      ),
      style: ThemeUtil.getNoteTextStyle(),
      maxLines: null,
      onChanged: (value) {
        _updateNoteContent = true;
        widget.note.noteContent = value;
      },
    );
  }

  _buildReorderNoteImgGridView({required int crossAxisCount}) {
    return ReorderableGridView.count(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 50),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 4, // 横轴距离
      mainAxisSpacing: 4, // 竖轴距离
      childAspectRatio: 1, // 网格比例。31/43为封面比例
      shrinkWrap: true, // 解决报错问题
      physics: const NeverScrollableScrollPhysics(), //解决不滚动问题
      children: List.generate(
        widget.note.relativeLocalImages.length,
        (index) => Container(
          key: UniqueKey(),
          // key: Key("${widget.note.relativeLocalImages.elementAt(index).imageId}"),
          child: _buildNoteItem(index),
        ),
      ),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final element = widget.note.relativeLocalImages.removeAt(oldIndex);
          widget.note.relativeLocalImages.insert(newIndex, element);
        });
      },
      // 表示长按多久可以拖拽
      dragStartDelay: const Duration(milliseconds: 100),
      // 拖拽时的组件
      dragWidgetBuilder: (int index, Widget child) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), // 边框的圆角
            border: Border.all(color: ThemeUtil.getPrimaryColor(), width: 4)),
        // 切割图片为圆角
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: buildImgWidget(
              url: widget.note.relativeLocalImages[index].path,
              showErrorDialog: false,
              isNoteImg: true),
        ),
      ),
      // 添加图片按钮
      footer: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: ThemeUtil.getPrimaryColor().withOpacity(0.1),
          ),
          child: TextButton(
              onPressed: () => _pickLocalImages(),
              child: const Icon(Icons.add)),
        )
      ],
    );
  }

  Stack _buildNoteItem(int imageIndex) {
    return Stack(
      children: [
        NoteImgItem(
          relativeLocalImages: widget.note.relativeLocalImages,
          initialIndex: imageIndex,
        ),
        // 删除按钮
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: const Color.fromRGBO(255, 255, 255, 0.1),
            ),
            child: GestureDetector(
                onTap: () => _dialogRemoveImage(imageIndex),
                child:
                    const Icon(Icons.close, color: Colors.white70, size: 18)),
          ),
        )
      ],
    );
  }

  _pickLocalImages() async {
    if (!ImageUtil.hasNoteImageRootDirPath()) {
      showToast("请先设置图片根目录");
      Navigator.of(context).push(
        // MaterialPageRoute(
        //   builder: (BuildContext context) =>
        //       const NoteSetting(),
        // ),
        FadeRoute(
          builder: (context) {
            return const ImagePathSetting();
          },
        ),
      );
      return;
    }
    if (Platform.isWindows || Platform.isAndroid) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: true,
      );
      if (result == null) return;
      List<PlatformFile> platformFiles = result.files;
      for (var platformFile in platformFiles) {
        String absoluteImagePath = platformFile.path ?? "";
        if (absoluteImagePath.isEmpty) continue;

        String relativeImagePath =
            ImageUtil.getRelativeNoteImagePath(absoluteImagePath);
        int imageId = await SqliteUtil.insertNoteIdAndImageLocalPath(
            widget.note.episodeNoteId, relativeImagePath);
        widget.note.relativeLocalImages
            .add(RelativeLocalImage(imageId, relativeImagePath));
      }
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    setState(() {});
  }

  _dialogRemoveImage(int index) {
    return showDialog(
        context: context,
        builder: (context) {
          // 返回警告对话框
          return AlertDialog(
            title: const Text("提示"),
            content: const Text("确认移除该图片吗？"),
            // 动作集合
            actions: <Widget>[
              TextButton(
                child: const Text("取消"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text("确认"),
                onPressed: () {
                  RelativeLocalImage relativeLocalImage =
                      widget.note.relativeLocalImages[index];
                  // 删除数据库记录、删除该页中的图片
                  SqliteUtil.deleteLocalImageByImageId(
                      relativeLocalImage.imageId);
                  widget.note.relativeLocalImages.removeWhere((element) =>
                      element.imageId == relativeLocalImage.imageId);
                  setState(() {});
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}
