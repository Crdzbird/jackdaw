# jackdaw_flutter

Flutter widgets for `jackdaw` agents.

```dart
final chat = ChatController(
  agent: Agent(model: model, tools: tools, store: InMemorySessionStore()),
  sessionId: 'support',
);

ChatView(controller: chat);
```

- `ChatView` shows the transcript, the answer as it streams, tool calls
  waiting for approval with their exact arguments, the last error and a
  composer with a stop button.
- `ChatController` exposes each piece of state as its own listenable, so
  you can build your own UI from the same parts.
- Streamed text is merged into at most one update per frame and rebuilds
  only the bubble that shows it, inside a repaint boundary, so a fast model
  does not cost the UI thread extra work. See claim C6 in the benchmarks of
  the repository.
- Stopping cancels the model and any running tool.

## Testing widgets that drive an agent

Cancelling an agent run finishes partly on the real event loop, which
`testWidgets` does not run on its own. Let both run in turn until the
future completes:

```dart
Future<void> settle(WidgetTester tester, Future<void> future) async {
  var done = false;
  unawaited(future.whenComplete(() => done = true));
  while (!done) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
}
```
