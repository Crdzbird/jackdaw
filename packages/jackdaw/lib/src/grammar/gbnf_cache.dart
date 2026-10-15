import 'package:jackdaw/src/grammar/gbnf_compiler.dart';
import 'package:jackdaw/src/schema/schema.dart';

final Expando<String> _grammars = Expando();

/// The grammar of [schema], compiled the first time it is asked for and
/// then kept for as long as the schema object lives, so a request reuses
/// the grammar of a schema it shares with earlier ones, such as the UI
/// schemas of a catalog.
String gbnfGrammar(Schema schema) =>
    _grammars[schema] ??= GbnfCompiler().compile(schema);
