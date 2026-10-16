import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The one Jaspr app of the page, which shows the surface of the round
/// running, or nothing, so each round's surface is disposed after it.
final class JasprHost extends StatefulComponent {
  /// Creates the host; `show` sets what it shows.
  const factory({Key? key}) = JasprHost._;

  const new _({super.key});

  /// Shows the surface it is given, or nothing for null.
  static void Function(SurfaceModel<JasprComponent>? surface) show = (_) {};

  @override
  State<JasprHost> createState() => _JasprHostState();
}

final class _JasprHostState extends State<JasprHost> {
  SurfaceModel<JasprComponent>? _surface;

  @override
  void initState() {
    super.initState();
    JasprHost.show = (surface) => setState(() => _surface = surface);
  }

  @override
  Component build(BuildContext context) => switch (_surface) {
    final surface? => Surface(surface: surface),
    null => const div([]),
  };
}
