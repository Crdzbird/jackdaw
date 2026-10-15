import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';

/// The flex weight a component takes inside a row or column.
const Schema basicWeight = Schema.number(
  description: 'Share of the free space inside a Row or Column.',
);

/// The checks of an input component.
final Schema basicChecks = Schema.array(
  items: UiType.checkRule.ref(),
  description: 'Rules the value must pass; the first failing one is shown.',
);

/// A string, binding or call described by [description].
Schema text(String description) =>
    UiType.dynamicString.ref(description: description);

/// One of [values], described by [description].
Schema choice(String description, List<String> values) =>
    Schema.string(enumValues: values, description: description);

/// The id of a child component, described by [description].
Schema child(String description) => UiType.child.ref(description: description);

/// The children of a container.
final Schema basicChildren = UiType.childList.ref(
  description: 'Child ids, or a template repeated for each item of a list.',
);

/// The names of the basic catalog's built-in icons.
const String basicIconNames =
    'accountCircle add arrowBack arrowForward attachFile calendarToday call '
    'camera check close delete download edit event error fastForward '
    'favorite favoriteOff folder help home info locationOn lock lockOpen mail '
    'menu moreVert moreHoriz notificationsOff notifications pause payment '
    'person phone photo play print refresh rewind search send settings share '
    'shoppingCart skipNext skipPrevious star starHalf starOff stop upload '
    'visibility visibilityOff volumeDown volumeMute volumeOff volumeUp '
    'warning';
