import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/relative_local_image.dart';
import 'package:flutter_test_future/components/error_image_builder.dart';
import 'package:flutter_test_future/utils/image_util.dart';

class ImageViewer extends StatefulWidget {
  final List<RelativeLocalImage> relativeLocalImages;
  final int initialIndex;

  const ImageViewer({
    Key? key,
    required this.relativeLocalImages,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  List<String> imageLocalPaths = [];
  int imagesCount = 0;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    for (var relativeLocalImage in widget.relativeLocalImages) {
      imageLocalPaths
          .add(ImageUtil.getAbsoluteImagePath(relativeLocalImage.path));
    }
    imagesCount = imageLocalPaths.length;

    // 首次进入可能选的是后面的图片，也需要移动
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      // 如果推迟，则会报错：Failed assertion: line 151 pos 12: '_positions.isNotEmpty': ScrollController not attached to any scroll views.
      scrollToCurrentImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("${currentIndex + 1} / ${imageLocalPaths.length}",
            style: const TextStyle(color: Colors.black)),
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _showImage(),
            _showScrollImages(),
          ],
        ),
      ),
    );
  }

  Offset? _initialOffset, _finalOffset;
  _showImage() {
    return Expanded(
      flex: 3,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: UniqueKey(),
          // 左右滑动图片
          child: GestureDetector(
            key: UniqueKey(),
            onHorizontalDragStart: (details) {
              _initialOffset = details.globalPosition;
            },
            onHorizontalDragUpdate: (details) {
              _finalOffset = details.globalPosition;
            },
            onHorizontalDragEnd: (details) {
              if (_initialOffset != null && _finalOffset != null) {
                final offsetDiff = _finalOffset!.dx - _initialOffset!.dx;
                if (offsetDiff > 0) {
                  debugPrint("右滑");
                  if (currentIndex - 1 >= 0) {
                    setState(() {
                      currentIndex--;
                    });
                  }
                } else {
                  debugPrint("左滑");
                  if (currentIndex + 1 < imageLocalPaths.length) {
                    setState(() {
                      currentIndex++;
                    });
                  }
                }
                scrollToCurrentImage();
              }
            },
            child: Image.file(
              File(imageLocalPaths[currentIndex]),
              errorBuilder: errorImageBuilder(
                  widget.relativeLocalImages[currentIndex].path),
            ),
          ),
        ),
      ),
    );
  }

  ScrollController _scrollController = ScrollController();
  _showScrollImages() {
    return Expanded(
        flex: 1,
        child: ListView.builder(
            controller: _scrollController, // 记得加上控制器
            itemCount: imageLocalPaths.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 点击共用轴中的图片
                  GestureDetector(
                    onTap: () {
                      if (currentIndex == index) {
                        return;
                      }
                      // 先设置当前下标，然后在移动
                      currentIndex = index;
                      scrollToCurrentImage();
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 8, right: 8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              width: 4,
                              color: index == currentIndex
                                  ? Colors.blueAccent
                                  : Colors.transparent)),
                      // 切割圆角图片
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(imageLocalPaths[index]),
                          fit: BoxFit.fitHeight,
                          height: 100,
                          width: 140,
                          errorBuilder: errorImageBuilder(
                              widget.relativeLocalImages[index].path),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }));
  }

  void scrollToCurrentImage() {
    _scrollController.animateTo(160.0 * (currentIndex - 1),
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }
}
