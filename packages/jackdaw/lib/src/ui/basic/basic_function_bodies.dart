import 'package:jackdaw/src/ui/basic/basic_check_bodies.dart';
import 'package:jackdaw/src/ui/basic/basic_format_bodies.dart';
import 'package:jackdaw/src/ui/basic/basic_logic_bodies.dart';
import 'package:jackdaw/src/ui/eval/ui_function_body.dart';

/// Implementations of all 14 functions of the basic catalog.
final Map<String, UiFunctionBody> basicFunctionBodies = {
  ...basicCheckBodies,
  ...basicFormatBodies,
  ...basicLogicBodies,
};
