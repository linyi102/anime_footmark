import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/pages/viewer/video/logic.dart';
import 'package:flutter_test_future/widgets/float_button.dart';
import 'package:flutter_test_future/widgets/multi_platform.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:path/path.dart' as p;

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({required this.url, this.title = '', Key? key})
      : super(key: key);
  final String url;
  final String title;

  @override
  State<VideoPlayerPage> createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerLogic logic = VideoPlayerLogic(url: widget.url);

  String get title => widget.title.isEmpty
      ? p.basenameWithoutExtension(widget.url)
      : widget.title;

  @override
  void dispose() {
    Get.delete<VideoPlayerLogic>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: logic,
      builder: (_) => Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          // progressIndicatorTheme:
          //     ProgressIndicatorThemeData(color: Theme.of(context).primaryColor),
        ),
        child: GestureDetector(
            onTap: () {
              // 桌面端单击播放/暂停
              if (Platform.isWindows) logic.player.playOrPause();
            },
            onDoubleTap: () {
              // 移动端双击播放/暂停
              if (!Platform.isAndroid) logic.player.playOrPause();
            },
            onLongPressStart: (details) => logic.longPressToSpeedUp(),
            onLongPressUp: () => logic.cancelSpeedUp(),
            onHorizontalDragStart: (details) => logic.player.pause(),
            onHorizontalDragUpdate: (details) =>
                logic.calculateWillSeekPosition(details.delta.dx),
            onHorizontalDragEnd: (details) => logic.seekDragEndPosition(),
            child: Stack(
              children: [
                _buildMultiPlatformVideoView(context),
                _buildFastForwarding(),
                _buildDragSeekPosition(),
                _buildScreenShotButton(),
                _buildScreenShotPreview(),
              ],
            )),
      ),
    );
  }

  /// 左右拖动改变进度位置
  _buildDragSeekPosition() {
    if (logic.willSeekPosition.isEmpty) return const SizedBox();
    return Align(
      alignment: Alignment.center,
      child: Text(
        logic.willSeekPosition,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(blurRadius: 3, color: Colors.black),
            ]),
        textAlign: TextAlign.center,
      ),
    );
  }

  MultiPlatform _buildMultiPlatformVideoView(BuildContext context) {
    return MultiPlatform(
      mobile: MaterialVideoControlsTheme(
        normal: MaterialVideoControlsThemeData(
          topButtonBar: _buildTopBar(context),
          volumeGesture: true,
        ),
        fullscreen: MaterialVideoControlsThemeData(
          topButtonBar: _buildTopBar(context),
          volumeGesture: true,
        ),
        child: _buildVideoView(),
      ),
      desktop: MaterialDesktopVideoControlsTheme(
        normal: MaterialDesktopVideoControlsThemeData(
            toggleFullscreenOnDoublePress: false,
            topButtonBar: _buildTopBar(context),
            bottomButtonBar: [
              const MaterialDesktopSkipPreviousButton(),
              const MaterialDesktopPlayOrPauseButton(),
              const MaterialDesktopSkipNextButton(),
              const MaterialDesktopVolumeButton(),
              const MaterialDesktopPositionIndicator(),
              const Spacer(),
              IconButton(
                  onPressed: logic.windowEnterOrExitFullscreen,
                  icon: const Icon(Icons.fullscreen))
            ]),
        // 自带的双击和右下角的全屏按钮，进入全屏是通过push一个新页面实现的，会导致手势失效和无法看到Stack上的组件，因此使用windowManager对当前页面进行全屏
        fullscreen: const MaterialDesktopVideoControlsThemeData(),
        child: _buildVideoView(),
      ),
    );
  }

  /// 长按倍速播放
  _buildFastForwarding() {
    if (!logic.fastForwarding) return const SizedBox();
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 80),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${logic.fastForwardRate.toInt()} 倍速播放中…',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  List<Widget> _buildTopBar(BuildContext context) {
    return [
      Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: Colors.white,
              shadows: _shadows,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              shadows: _shadows,
            ),
          ),
        ],
      )
    ];
  }

  List<Shadow> get _shadows =>
      [const Shadow(blurRadius: 3, color: Colors.black)];

  _buildVideoView() => Video(controller: logic.videoController);

  _buildScreenShotPreview() {
    if (logic.screenShotFile == null) {
      return const SizedBox();
    }

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, Global.getAppBarHeight(context), 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                child: SizedBox(
                  width: 100,
                  // 使用文件显示截图时，加载时没有高度，因此取消按钮会在上方，加载完毕后下移
                  child: Image.file(logic.screenShotFile!),
                ),
              ),
            ),
            const SizedBox(height: 5),
            InkWell(
              onTap: logic.deleteScreenShotFile,
              child: Card(
                color: Colors.white,
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    width: 100,
                    child: const Center(
                        child:
                            Text("删除", style: TextStyle(color: Colors.black)))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildScreenShotButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: FloatButton(
        icon: MingCuteIcons.mgc_camera_2_line,
        onTap: () => logic.capture(),
      ),
    );
  }
}