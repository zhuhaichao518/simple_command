import 'dart:convert';
import 'dart:io';

import 'package:simple_command/app_settings.dart';
import 'package:simple_command/settings_screen.dart';
import 'package:simple_command/src/platform_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings().loadSettings(); // Load settings
  runApp(MyApp());
}

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimpleCommand',
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(), // Define the dark theme
      themeMode: ThemeMode.dark, // Force the app to use the dark theme
      home: AppPlatformMenu(child: Home()),
    );
  }
}

class Home extends StatefulWidget {
  Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  TabController? _tabController;
  List<TabData> _tabs = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < AppSettings().initialTabCount; i++) {
      _addNewTab(AppSettings().initialTabs[i]);
    }
  }

  void _initializeTabController() {
    if (_tabController != null) {
      _tabController!.dispose(); // 释放旧的 TabController
    }
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(() {
      setState(() {
        _currentIndex = _tabController!.index;
      });
    });
  }

void _addNewTab(TabSetting setting) {
  final terminal = Terminal(maxLines: 10000);
  final terminalController = TerminalController();
  final pty = Pty.start(
    shell,
    columns: terminal.viewWidth,
    rows: terminal.viewHeight,
    workingDirectory: setting.directory,
  );

  pty.output
      .cast<List<int>>()
      .transform(Utf8Decoder())
      .listen(terminal.write);

  pty.exitCode.then((code) {
    terminal.write('The process exited with exit code $code');
  });

  terminal.onOutput = (data) {
    pty.write(const Utf8Encoder().convert(data));
  };

  terminal.onResize = (w, h, pw, ph) {
    pty.resize(h, w);
  };

  final tabData = TabData(
    terminal: terminal,
    terminalController: terminalController,
    pty: pty,
    title: setting.title,
    buttons: setting.buttons,
  );

  setState(() {
    _tabs.add(tabData);
    _initializeTabController();
    if (_tabController != null) _tabController!.index = _tabs.length - 1;
  });
}

  void _closeTab(int index) {
    setState(() {
      _tabs[index].pty.kill(); // 关闭相关Pty
      _tabs.removeAt(index);
      _currentIndex =
          (_currentIndex >= _tabs.length) ? _tabs.length - 1 : _currentIndex;
      _initializeTabController();
    });
  }

  Widget buildCommandButtons(List<CommandButton> buttons) {
  return Container(
    height: 50,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: buttons.length,
      itemBuilder: (BuildContext context, int index) {
        return ElevatedButton(
          onPressed: () {
            final commandString = buttons[index].command + '\n';
            final Uint8List command = Uint8List.fromList(utf8.encode(commandString));
            _tabs[_currentIndex].pty.write(command);
          },
          child: Text(buttons[index].name),
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(36), // 调整高度以使标签页更矮
        child: Container(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: Row(
            children: [
              Expanded(
                child: _tabs.isEmpty
                    ? SizedBox.shrink() // 隐藏 TabBar 如果没有标签
                    : TabBar(
                        padding: EdgeInsets.only(left: 0),
                        controller: _tabController,
                        isScrollable: true,
                        onTap: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelPadding:
                            EdgeInsets.symmetric(horizontal: 5), // 减小标签的内边距
                        tabs: _tabs
                            .asMap()
                            .entries
                            .map((entry) => Tab(
                                  height: 30, // 设置 Tab 的高度
                                  child: Row(
                                    children: [
                                      Text(entry.value.title,
                                          style: TextStyle(
                                              fontSize: 12)), // 调整字体大小
                                      IconButton(
                                        icon: Icon(Icons.close,
                                            size: 16), // 调整关闭按钮的大小
                                        padding: EdgeInsets.zero, // 移除内边距
                                        constraints: BoxConstraints(), // 移除约束
                                        onPressed: () => _closeTab(entry.key),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
              ),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingsManager()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed:() {
                  _addNewTab(TabSetting(title: "new tab",directory: "~", buttons: []));
                },
              ),
            ],
          ),
        ),
      ),
      body: _tabs.isEmpty
          ? Center(child: Text('No Terminals Open'))
          : Column(
      children: [
        Expanded(
          child: _tabs.isEmpty
            ? Center(child: Text('No Terminals Open'))
            :           TerminalView(
              _tabs[_currentIndex].terminal,
              controller: _tabs[_currentIndex].terminalController,
              autofocus: true,
              backgroundOpacity: 0.7,
              onSecondaryTapDown: (details, offset) async {
                final selection =
                    _tabs[_currentIndex].terminalController.selection;
                if (selection != null) {
                  final text =
                      _tabs[_currentIndex].terminal.buffer.getText(selection);
                  _tabs[_currentIndex].terminalController.clearSelection();
                  await Clipboard.setData(ClipboardData(text: text));
                } else {
                  final data = await Clipboard.getData('text/plain');
                  final text = data?.text;
                  if (text != null) {
                    _tabs[_currentIndex].terminal.paste(text);
                  }
                }
              },
            ),
        ),
        if (_tabs.isNotEmpty && _tabs[_currentIndex].buttons.length>0) buildCommandButtons(_tabs[_currentIndex].buttons)
      ],
    ),
          
          
          
        
    );
  }
}

class TabData {
  final Terminal terminal;
  final TerminalController terminalController;
  final Pty pty;
  final String title;
  final List<CommandButton> buttons;

  TabData({
    required this.terminal,
    required this.terminalController,
    required this.pty,
    required this.title,
    this.buttons = const [],
  });
}

String get shell {
  if (Platform.isMacOS || Platform.isLinux) {
    return Platform.environment['SHELL'] ?? 'bash';
  }

  if (Platform.isWindows) {
    return 'cmd.exe';
  }

  return 'sh';
}
