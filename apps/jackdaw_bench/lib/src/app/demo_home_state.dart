import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/agent_chat.dart';
import 'package:jackdaw_bench/src/app/demo_home.dart';
import 'package:jackdaw_bench/src/app/playground_view.dart';
import 'package:jackdaw_bench/src/app/ui_studio.dart';

/// State of [DemoHome]: which tab is shown.
class DemoHomeState extends State<DemoHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('jackdaw on device')),
    body: IndexedStack(
      index: _tab,
      children: [
        AgentChat(model: widget.model, sessions: widget.sessions),
        UiStudio(model: widget.model),
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
