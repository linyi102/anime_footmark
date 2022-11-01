import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/pages/main_screen.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'components/update_hint.dart';
import 'controllers/anime_display_controller.dart';
import 'controllers/update_record_controller.dart';

void main() {
  beforeRunApp().then((value) => runApp(const GetMaterialApp(home: MyApp())));
}

Future<void> beforeRunApp() async {
  // 透明状态栏
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  // 确保初始化，否则Unhandled Exception: Null check operator used on a null value
  WidgetsFlutterBinding.ensureInitialized();
  // 获取SharedPreferences
  await SPUtil.getInstance();
  // 桌面应用的sqflite初始化
  sqfliteFfiInit();
  // 确保数据库表最新结构
  await SqliteUtil.ensureDBTable();
  // put常用的getController
  putGetController();
  // 设置Windows窗口
  handleWindowsManager();
  // 解决访问部分网络图片时报错CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate
  HttpOverrides.global = MyHttpOverrides();
}

void putGetController() {
  Get.put(UpdateRecordController()); // 放在ensureDBTable后，因为init中访问到了表
  Get.put(AnimeDisplayController());
}

void handleWindowsManager() async {
  // 只在Windows系统下开启窗口设置，否则Android端会白屏
  if (Platform.isWindows) {
    // Windows端窗口设置
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      title: "漫迹",
      size: Size(SpProfile.getWindowWidth(), SpProfile.getWindowHeight()),
      // 最小尺寸
      // minimumSize: const Size(900, 600),
      minimumSize: const Size(300, 300),
      fullScreen: false,
      // 需要居中，否则会偏右
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      // titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WindowListener {
  // StatefulWidget才有initState和dispose
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
    _autoBackup();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    // Add this line to override the default close handler
    if (Platform.isWindows) await windowManager.setPreventClose(true);
    setState(() {});
  }

  @override
  void onWindowResize() async {}

  @override
  void onWindowClose() async {
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      // 关闭窗口前等待记录窗口大小完毕
      await SpProfile.setWindowSize(await windowManager.getSize());
      // 退出
      Navigator.of(context).pop();
      await windowManager.destroy();
    }
  }

  @override
  void onWindowMaximize() async {
    debugPrint("全屏");
  }

  _autoBackup() async {
    // 之前登录过，因为关闭应用会导致连接关闭，所以下次重启应用时需要再次连接
    if (SPUtil.getBool("login")) {
      await WebDavUtil.initWebDav(
        SPUtil.getString("webdav_uri"),
        SPUtil.getString("webdav_user"),
        SPUtil.getString("webdav_password"),
      );
    }
    // 如果都设置了自动备份，则只需要压缩一次
    if (SPUtil.getBool("auto_backup_local") &&
        SPUtil.getBool("auto_backup_webdav")) {
      debugPrint("准备本地和WebDav自动备份");
      BackupUtil.backup(
        localBackupDirPath:
            SPUtil.getString("backup_local_dir", defaultValue: "unset"),
        remoteBackupDirPath: await WebDavUtil.getRemoteDirPath(),
        showToastFlag: false,
        automatic: true,
      );
    } else if (SPUtil.getBool("auto_backup_local")) {
      debugPrint("准备本地自动备份");
      BackupUtil.backup(
        localBackupDirPath:
            SPUtil.getString("backup_local_dir", defaultValue: "unset"),
        showToastFlag: false,
        automatic: true,
      );
    } else if (SPUtil.getBool("auto_backup_webdav")) {
      debugPrint("准备WebDav自动备份");
      BackupUtil.backup(
        remoteBackupDirPath: await WebDavUtil.getRemoteDirPath(),
        showToastFlag: false,
        automatic: true,
      );
      // String lastTimeBackup = SPUtil.getString("last_time_backup");
      // // 不为空串表示之前备份过
      // if (lastTimeBackup != "") {
      //   debugPrint("上次备份的时间：$lastTimeBackup");
      //   DateTime dateTime = DateTime.parse(lastTimeBackup);
      //   DateTime now = DateTime.now();
      //   // 距离上次备份超过1天，则进行备份
      //   // if (now.difference(dateTime).inSeconds >= 10) {
      //   if (now.difference(dateTime).inDays >= 1) {
      //     // WebDavUtil.backupData(true);
      //   }
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());

    return Obx(() => OKToast(
          position: ToastPosition.top,
          // true表示弹出消息时会先关闭前一个消息
          dismissOtherOnShow: true,
          radius: 20,
          textPadding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          backgroundColor:
              themeController.isDarkMode.value ? Colors.white : Colors.black,
          textStyle: TextStyle(
              color: themeController.isDarkMode.value
                  ? Colors.black
                  : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
              fontFamilyFallback: themeController.fontFamilyFallback),
          child: MaterialApp(
            // 后台应用显示名称
            title: '漫迹',
            home: Stack(
              children: const [
                MainScreen(),
                UpdateHint(checkLatestVersion: true)
              ],
            ),
            // 自定义滚动行为
            scrollBehavior: MyCustomScrollBehavior(),
            theme: buildThemeData(themeController),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              //对应的Cupertino风格（iOS风格组件）
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CH'),
              Locale('en', 'US'),
            ],
          ),
        ));
  }

  /// 自定义primarySwatch，用于指定回弹颜色
  /// 来源：[Flutter 如何自定义primarySwatch颜色 - 掘金](https://juejin.cn/post/7012818692035756045)
  MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  ThemeData buildThemeData(ThemeController themeController) {
    TextStyle textStyle =
        TextStyle(fontFamilyFallback: themeController.fontFamilyFallback);

    return ThemeData(
      // primarySwatch: createMaterialColor(Colors.amber),
      brightness:
          themeController.isDarkMode.value ? Brightness.dark : Brightness.light,
      // 保证全局使用自定义字体，当自定义字体失效时，就会使用下面的后备字体
      fontFamily: "invalidFont",
      cardTheme: CardTheme(color: ThemeUtil.getCardColor()),
      popupMenuTheme:
          PopupMenuThemeData(color: ThemeUtil.getAppBarBackgroundColor()),
      dialogTheme: DialogTheme(backgroundColor: ThemeUtil.getCardColor()),
      textTheme: TextTheme(
        // ListTile标题
        subtitle1: textStyle,
        // 按钮里的文字
        button: textStyle,
        // 底部tab，ListTile副标题
        bodyText2: textStyle,
        // Text
        bodyText1: textStyle,
        // 未知
        // subtitle2: textStyle,
        // overline: textStyle,
        // caption: textStyle,
        // headline1: textStyle,
        // headline2: textStyle,
        // headline3: textStyle,
        // headline4: textStyle,
        // headline5: textStyle,
        // AppBar里的title
        // headline6: textStyle,
      ),
      appBarTheme: AppBarTheme(
        shadowColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        foregroundColor: ThemeUtil.getFontColor(),
        backgroundColor: ThemeUtil.getAppBarBackgroundColor(),
        iconTheme: IconThemeData(
          color: ThemeUtil.getIconButtonColor(),
        ),
      ),
      iconTheme: IconThemeData(
        color: ThemeUtil.getIconButtonColor(),
      ),
      scaffoldBackgroundColor: ThemeUtil.getScaffoldBackgroundColor(),
      inputDecorationTheme: InputDecorationTheme(
        suffixIconColor: ThemeUtil.getIconButtonColor(),
      ),
      listTileTheme: ListTileThemeData(
        iconColor:
            themeController.isDarkMode.value ? Colors.white70 : Colors.black54,
        style: ListTileStyle.drawer,
        // dense: true,
        // 会影响副标题颜色
        // textColor: ThemeUtil.getFontColor(),
      ),
      radioTheme:
          RadioThemeData(fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ThemeUtil.getThemePrimaryColor();
        }
        return null;
      })),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: ThemeUtil.getThemePrimaryColor()),
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
              textStyle: MaterialStateProperty.all(
                  const TextStyle(color: Colors.black)))),
      tabBarTheme: TabBarTheme(
        unselectedLabelColor:
            themeController.isDarkMode.value ? Colors.white70 : Colors.black54,
        labelColor: ThemeUtil.getThemePrimaryColor(), // 选中的tab字体颜色
        // tabbar不要再添加labelStyle，否则此处设置无效
        labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamilyFallback: themeController.fontFamilyFallback),
        unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamilyFallback: themeController.fontFamilyFallback),
      ),
      // 滚动条主题
      scrollbarTheme: ScrollbarThemeData(
        trackVisibility: MaterialStateProperty.all(true),
        thickness: MaterialStateProperty.all(5),
        interactive: true,
        radius: const Radius.circular(10),
        thumbColor: MaterialStateProperty.all(
          themeController.isDarkMode.value
              ? const Color.fromRGBO(80, 80, 80, 1.0)
              : const Color.fromRGBO(160, 160, 160, 1.0),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// Enable scrolling with mouse dragging
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
