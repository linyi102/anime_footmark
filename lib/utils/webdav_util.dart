import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:webdav_client/webdav_client.dart';

class WebDavUtil {
  static WebDavUtil? _webDavUtil;
  WebDavUtil._();
  static WebDavUtil getInstance() {
    return _webDavUtil ??= WebDavUtil._();
  }

  static late Client client;

  static Future<bool> initWebDav(
      String uri, String user, String password) async {
    client = newClient(
      uri,
      user: user,
      password: password,
      debug: false,
    );
    if (!(await pingWebDav())) {
      debugPrint("WebDav初始化失败！");
      return false;
    }
    // Set the public request headers
    client.setHeaders({'accept-charset': 'utf-8'});

    // Set the connection server timeout time in milliseconds.
    client.setConnectTimeout(8000);

    // Set send data timeout time in milliseconds.
    client.setSendTimeout(8000);

    // Set transfer data time in milliseconds.
    client.setReceiveTimeout(8000);
    debugPrint("WebDav初始化成功！");
    return true;
  }

  static Future<bool> pingWebDav() async {
    try {
      await client.ping();
    } catch (e) {
      SPUtil.setBool("login", false); // 如果之前成功，但现在失败了，所以需要覆盖
      print("ping false");
      return false;
    }
    SPUtil.setBool("login", true);
    print("ping ok");
    return true;
  }

  static Future<void> upload(String localPath, String remotePath) async {
    return client.writeFromFile(
      localPath,
      remotePath,
    );
  }

  static Future<String> getRemoteDirPath() async {
    // 先判断是否有animetrace目录，没有则创建
    var list = await client.readDir('/');
    bool existBackupDir = false;
    for (var file in list) {
      if (file.name == "animetrace") {
        existBackupDir = true;
        break;
      }
    }
    String backupDir = "/animetrace";
    if (!existBackupDir) {
      await client.mkdir(backupDir);
    }
    return backupDir;
  }
}
