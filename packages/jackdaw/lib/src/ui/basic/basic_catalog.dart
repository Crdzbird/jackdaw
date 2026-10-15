import 'package:jackdaw/src/ui/basic/basic_check_functions.dart';
import 'package:jackdaw/src/ui/basic/basic_display_components.dart';
import 'package:jackdaw/src/ui/basic/basic_format_functions.dart';
import 'package:jackdaw/src/ui/basic/basic_input_components.dart';
import 'package:jackdaw/src/ui/basic/basic_layout_components.dart';
import 'package:jackdaw/src/ui/basic/basic_logic_functions.dart';
import 'package:jackdaw/src/ui/basic/basic_picker_components.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';

/// The A2UI v1.0 basic catalog: 18 components and 14 functions that every
/// A2UI renderer understands.
final UiCatalog basicCatalog = UiCatalog(
  id: 'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json',
  title: 'A2UI Basic Catalog',
  components: [
    ...basicDisplayComponents,
    ...basicLayoutComponents,
    ...basicInputComponents,
    ...basicPickerComponents,
  ],
  functions: [
    ...basicCheckFunctions,
    ...basicFormatFunctions,
    ...basicLogicFunctions,
  ],
  instructions: basicInstructions,
);

/// Guidance on using the basic catalog, given to the model.
const String basicInstructions =
    'Arrange components with Row and Column. There are no operators: to '
    r'put data into text, use formatString, as in formatString("Hi ${/user/name}"). '
    'Place each component inside the container the request names. Put the '
    'message of a failing check in the check itself rather than in a '
    'separate Text.';
