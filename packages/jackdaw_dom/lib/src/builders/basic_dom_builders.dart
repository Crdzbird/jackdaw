import 'package:jackdaw_dom/src/builders/ui_dom_control_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_layout_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_range_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_text_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_text_field.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';

/// Builders for the components of the A2UI v1.0 basic catalog that draw
/// as plain HTML so far: layout, text, dividers, buttons and inputs.
const Map<String, UiDomBuilder> basicDomBuilders = {
  'Text': uiDomText,
  'Row': uiDomRow,
  'Column': uiDomColumn,
  'List': uiDomList,
  'Card': uiDomCard,
  'Divider': uiDomDivider,
  'Button': uiDomButton,
  'TextField': uiDomTextField,
  'CheckBox': uiDomCheckBox,
  'Slider': uiDomSlider,
};
