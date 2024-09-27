import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Class to represent a command button
class CommandButton {
  String name;
  String command;

  CommandButton({required this.name, required this.command});

  factory CommandButton.fromJson(Map<String, dynamic> jsonData) {
    return CommandButton(
      name: jsonData['name'],
      command: jsonData['command'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'command': command,
    };
  }
}

// Updated TabSetting class to include a list of CommandButton
class TabSetting {
  String directory;
  String title;
  List<CommandButton> buttons; // List of buttons for each tab

  TabSetting({
    required this.directory,
    required this.title,
    this.buttons=const [], // Initialize with an empty list by default
  });

  factory TabSetting.fromJson(Map<String, dynamic> jsonData) {
    List<CommandButton> loadedButtons = [];
    if (jsonData['buttons'] != null) {
      loadedButtons = (jsonData['buttons'] as List)
          .map((buttonData) => CommandButton.fromJson(buttonData))
          .toList();
    }
    return TabSetting(
      directory: jsonData['directory'],
      title: jsonData['title'],
      buttons: loadedButtons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'directory': directory,
      'title': title,
      'buttons': buttons.map((button) => button.toJson()).toList(),
    };
  }
}

// AppSettings class
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