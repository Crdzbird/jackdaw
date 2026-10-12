import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/model/finish_reason.dart';
import 'package:jackdaw/src/model/usage.dart';

part 'finish_event.dart';
part 'text_delta.dart';
part 'tool_call_event.dart';

/// One event in the stream produced by a language model.
sealed class ModelEvent {
  const new _();
}
