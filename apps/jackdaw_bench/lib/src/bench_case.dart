import 'package:jackdaw/jackdaw.dart';

/// One structured-output benchmark case.
final class BenchCase {
  const factory(String prompt, Schema schema) = BenchCase._;

  const new _(this.prompt, this.schema);

  final String prompt;
  final Schema schema;
}
