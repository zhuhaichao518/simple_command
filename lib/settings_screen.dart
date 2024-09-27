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
  final TextEditingController _buttonNameController = TextEditingController();
  final TextEditingController _buttonCommandController = TextEditingController();
  int? editingIndex;
  int? editingButtonIndex;

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
    if (editingIndex != null) {
      // Update existing tab
      tabs[editingIndex!].directory = _directoryController.text;
      tabs[editingIndex!].title = _titleController.text;
    } else {
      // Add new tab with empty buttons list
      tabs.add(TabSetting(directory: _directoryController.text, title: _titleController.text, buttons: []));
    }
    saveSettings();
    clearInputs();
  }

  void clearInputs() {
    setState(() {
      _directoryController.clear();
      _titleController.clear();
      _buttonNameController.clear();
      _buttonCommandController.clear();
      editingIndex = null;
      editingButtonIndex = null;
    });
  }

  void startEditing(int index) {
    setState(() {
      _directoryController.text = tabs[index].directory;
      _titleController.text = tabs[index].title;
      editingIndex = index;
    });
  }

  void startEditingButton(int tabIndex, int buttonIndex) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Edit Button'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    TextField(
                                      controller: _buttonNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Button Name',
                                      ),
                                    ),
                                    TextField(
                                      controller: _buttonCommandController,
                                      decoration: const InputDecoration(
                                        labelText: 'Command',
                                      ),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      saveOrUpdateButton();
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
    setState(() {
      _buttonNameController.text = tabs[tabIndex].buttons[buttonIndex].name;
      _buttonCommandController.text = tabs[tabIndex].buttons[buttonIndex].command;
      editingIndex = tabIndex;
      editingButtonIndex = buttonIndex;
    });
  }

  void saveOrUpdateButton() {
    final newButton = CommandButton(
      name: _buttonNameController.text,
      command: _buttonCommandController.text,
    );
    if (editingButtonIndex != null) {
      tabs[editingIndex!].buttons[editingButtonIndex!] = newButton;
    } else {
      tabs[editingIndex!].buttons.add(newButton);
    }
    saveSettings();
    clearInputs();
    setState(() {
    });
  }

  void deleteButton(int tabIndex, int buttonIndex) {
    setState(() {
      tabs[tabIndex].buttons.removeAt(buttonIndex);
      saveSettings();
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
                        icon: Icon(Icons.add),
                        onPressed: () {
                          editingIndex = index;
                          editingButtonIndex = null;
                          _buttonNameController.clear();
                          _buttonCommandController.clear();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Add Button'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    TextField(
                                      controller: _buttonNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Button Name',
                                      ),
                                    ),
                                    TextField(
                                      controller: _buttonCommandController,
                                      decoration: const InputDecoration(
                                        labelText: 'Command',
                                      ),
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      saveOrUpdateButton();
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
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
                  onTap: () {
                    // Show details and buttons for editing
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Edit Buttons for "${tab.title}"'),
                          content: SizedBox(
                            height: 300,
                            width: 300,
                            child: ListView.builder(
                              itemCount: tab.buttons.length,
                              itemBuilder: (context, buttonIndex) {
                                final button = tab.buttons[buttonIndex];
                                return ListTile(
                                  title: Text(button.name),
                                  subtitle: Text(button.command),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          startEditingButton(index, buttonIndex);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          deleteButton(index, buttonIndex);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _directoryController,
              decoration: const InputDecoration(labelText: 'Directory'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
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