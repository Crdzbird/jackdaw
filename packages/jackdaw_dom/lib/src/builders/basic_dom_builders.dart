import 'package:jackdaw_dom/src/builders/ui_dom_choice_picker.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_container_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_control_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_date_time.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_icon.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_layout_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_media_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_range_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_text_builders.dart';
import 'package:jackdaw_dom/src/builders/ui_dom_text_field.dart';
import 'package:jackdaw_dom/src/ui_dom_part.dart';

/// Builders for all 18 components of the A2UI v1.0 basic catalog.
const Map<String, UiDomBuilder> basicDomBuilders = {
  'Text': uiDomText,
  'Image': uiDomImage,
  'Icon': uiDomIcon,
  'Video': uiDomVideo,
  'AudioPlayer': uiDomAudioPlayer,
  'Row': uiDomRow,
  'Column': uiDomColumn,
  'List': uiDomList,
  'Card': uiDomCard,
  'Tabs': uiDomTabs,
  'Modal': uiDomModal,
  'Divider': uiDomDivider,
  'Button': uiDomButton,
  'TextField': uiDomTextField,
  'CheckBox': uiDomCheckBox,
  'ChoicePicker': uiDomChoicePicker,
  'Slider': uiDomSlider,
  'DateTimeInput': uiDomDateTime,
};
