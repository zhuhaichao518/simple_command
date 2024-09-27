import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:simple_command/app_settings.dart';

class SettingsManager extends StatefulWidget {
  @override
  _SettingsManagerState createState() => _SettingsManagerState();
}

class _SettingsManagerState extends State<SettingsManager> {
  List<TabSetting> tabs = [];
  final TextEditingController _directoryController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  int? editingIndex; // Index of the tab being edited, null if adding new

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? tabSettingsJson = prefs.getString('tabSettings');
    if (tabSettingsJson != null) {
      setState(() {
        tabs = (json.decode(tabSettingsJson) as List)
            .map((data) => TabSetting.fromJson(data))
            .toList();
      });
    }
  }

  void saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonTabs = json.encode(tabs.map((tab) => tab.toJson()).toList());
    prefs.setString('tabSettings', jsonTabs);
  }

  void saveOrUpdateTabSetting() {
    final newSetting = TabSetting(
      directory: _directoryController.text,
      title: _titleController.text,
    );
    if (editingIndex != null) {
      // Update existing tab
      tabs[editingIndex!] = newSetting;
    } else {
      // Add new tab
      tabs.add(newSetting);
    }
    saveSettings();
    clearInputs();
  }

  void clearInputs() {
    setState(() {
      _directoryController.clear();
      _titleController.clear();
      editingIndex = null; // Reset editing index
    });
  }

  void startEditing(int index) {
    setState(() {
      _directoryController.text = tabs[index].directory;
      _titleController.text = tabs[index].title;
      editingIndex = index;
    });
  }

  void deleteTabSetting(int index) {
    setState(() {
      tabs.removeAt(index);
      saveSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Default Tab Settings"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return ListTile(
                  title: Text(tab.title),
                  subtitle: Text(tab.directory),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => startEditing(index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteTabSetting(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _directoryController,
              decoration: InputDecoration(labelText: 'Directory'),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
          ),
          ElevatedButton(
            onPressed: saveOrUpdateTabSetting,
            child: Text(editingIndex == null ? 'Add Default Tab' : 'Update Tab'),
          )
        ],
      ),
    );
  }
}