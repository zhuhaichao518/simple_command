import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TabSetting {
  String directory;
  String title;

  TabSetting({required this.directory, required this.title});

  factory TabSetting.fromJson(Map<String, dynamic> jsonData) {
    return TabSetting(
      directory: jsonData['directory'],
      title: jsonData['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'directory': this.directory,
      'title': this.title,
    };
  }
}

class AppSettings {
  static final AppSettings _instance = AppSettings._internal();

  factory AppSettings() {
    return _instance;
  }

  AppSettings._internal();

  int initialTabCount = 0;
  List<TabSetting> initialTabs = [];

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? tabSettingsJson = prefs.getString('tabSettings');
    if (tabSettingsJson != null) {
        initialTabs = (json.decode(tabSettingsJson) as List)
            .map((data) => TabSetting.fromJson(data))
            .toList();
        initialTabCount = initialTabs.length;
    }
  }
}