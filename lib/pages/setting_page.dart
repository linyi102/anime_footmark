import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/scaffolds/about_version.dart';
import 'package:flutter_test_future/scaffolds/anime_display_setting.dart';
import 'package:flutter_test_future/scaffolds/backup_restore.dart';
import 'package:flutter_test_future/scaffolds/tag_manage.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  File? _imgFile;
  bool loadOk = false;

  @override
  void initState() {
    super.initState();
    // SPUtil.clear();
    // WebDavUtil.pingWebDav();
    String imgFilePath = SPUtil.getString("img_file_path");
    if (imgFilePath.isNotEmpty) {
      _imgFile = File(imgFilePath);
    }
    Future.delayed(Duration.zero).then((value) {
      loadOk = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    // SPUtil.setString("img_file_path", "");
    super.dispose();
  }

  // String getDuration() {
  //   DateTime now = DateTime.now();
  //   String lastSharedTime = SPUtil.getString("lastSharedTime");
  //   if (lastSharedTime.isNotEmpty) {
  //     DateTime before = DateTime.parse(lastSharedTime);
  //     int inDays = now.difference(before).inDays;
  //     if (inDays == 0) {
  //       return "今天备份过";
  //     } else {
  //       return "$inDays天前备份过";
  //     }
  //   }
  //   return "";
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "更多",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: !loadOk
            ? Container()
            : ListView(
                key: UniqueKey(),
                children: [
                  // ListTile(
                  //   title: const Text("创建备份"),
                  //   subtitle: const Text("备份动漫记录"),
                  //   onTap: () async {
                  //     // 首先判断备份目录是否存在
                  //     String backupDir = SPUtil.getString("backup_path");
                  //     if (!(await Directory(backupDir).exists())) {
                  //       showToast("备份之前请先设置备份目录！");
                  //       return;
                  //     }
                  //     // 拷贝数据库文件到备份目录下
                  //     final backupFilePath =
                  //         "$backupDir/anime_trace_${DateTime.now()}.db";
                  //     if (await Permission.storage.request().isGranted) {
                  //       await File(SqliteUtil.dbPath).copy(backupFilePath);
                  //       showToast("备份成功");
                  //     }
                  //   },
                  // ),
                  _showImg(),
                  _showImgButton(),
                  Platform.isAndroid ? _showImg() : Container(),
                  Platform.isAndroid ? _showImgButton() : Container(),
                  ListTile(
                    leading: const Icon(
                      Icons.settings_backup_restore_outlined,
                      color: Colors.blue,
                    ),
                    title: const Text("备份还原"),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const BackupAndRestore()));
                    },
                  ),
                  // const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.new_label_outlined,
                      color: Colors.blue,
                    ),
                    title: const Text("标签管理"),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const TagManage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.book_outlined,
                      color: Colors.blue,
                    ),
                    title: const Text("动漫界面"),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const AnimesDisplaySetting()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.error_outline,
                      color: Colors.blue,
                    ),
                    title: const Text("关于版本"),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const AboutVersion()));
                    },
                  )
                ],
              ),
      ),
    );
  }

  _showImg() {
    return _imgFile == null
        ? Container()
        : SizedBox(
            height: MediaQuery.of(context).size.height / 4,
            width: MediaQuery.of(context).size.width,
            child: Card(
              elevation: 5,
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5))), // 圆角
              clipBehavior: Clip.antiAlias, // 设置抗锯齿，实现圆角背景
              // elevation: 0,
              // margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Image.file(
                _imgFile as File,
                fit: BoxFit.fitWidth,
              ),
            ),
          );
  }

  _showImgButton() {
    return ListTile(
      leading: const Icon(
        // Icons.image_outlined,
        Icons.wallpaper_outlined,
        color: Colors.blue,
      ),
      title: const Text("设置图片"),
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom, allowedExtensions: ["jpg", "png", "gif"]);
        if (result != null) {
          PlatformFile imgae = result.files.single;
          String path = imgae.path as String;
          SPUtil.setString("img_file_path", path);
          _imgFile = File(path);
          setState(() {});
        }
      },
      onLongPress: () {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("取消图片"),
                content: const Text("确认取消图片吗？"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () {
                        SPUtil.setString("img_file_path", "");
                        _imgFile = null; // 需要将该成员设置会null，setState才有效果
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                      child: const Text("确认")),
                ],
              );
            });
      },
    );
  }
}
