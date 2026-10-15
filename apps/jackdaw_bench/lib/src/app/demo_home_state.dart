import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/agent_chat.dart';
import 'package:jackdaw_bench/src/app/demo_home.dart';
import 'package:jackdaw_bench/src/app/model_path.dart';
import 'package:jackdaw_bench/src/app/playground_view.dart';
import 'package:jackdaw_bench/src/app/ui_studio.dart';

/// State of [DemoHome]: which tab is shown. After the first screen the UI
/// tab builds, the processed prompt is saved, so the next launch loads it
/// instead of processing the long UI prompt again.
class DemoHomeState extends State<DemoHome> {
  int _tab = 0;

  Future<void> _saveUiState() async {
    final file = uiStateFile(widget.sessions);
    if (!file.existsSync()) await widget.model.saveState(file);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('jackdaw on device')),
    body: IndexedStack(
      index: _tab,
      children: [
        AgentChat(model: widget.model, sessions: widget.sessions),
        UiStudio(model: widget.model, onBuilt: _saveUiState),
        PlaygroundView(model: widget.model),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (tab) => setState(() => _tab = tab),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Chat'),
        NavigationDestination(
          icon: Icon(Icons.dashboard_customize_outlined),
          label: 'UI',
        ),
        NavigationDestination(icon: Icon(Icons.tune), label: 'Playground'),
      ],
    ),
  );
}
