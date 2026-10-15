import 'package:jackdaw_flutter/src/ui/builders/ui_choice_picker.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_container_builders.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_control_builders.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_layout_builders.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_media_builders.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_player_builders.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_range_builders.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_text_builders.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_text_field.dart';
import 'package:jackdaw_flutter/src/ui/ui_widget_builder.dart';

/// Builders for all 18 components of the A2UI v1.0 basic catalog.
const Map<String, UiWidgetBuilder> basicUiBuilders = {
  'Text': uiTextWidget,
  'Image': uiImageWidget,
  'Icon': uiIconWidget,
  'Video': uiVideoWidget,
  'AudioPlayer': uiAudioPlayerWidget,
  'Row': uiRowWidget,
  'Column': uiColumnWidget,
  'List': uiListWidget,
  'Card': uiCardWidget,
  'Tabs': uiTabsWidget,
  'Modal': uiModalWidget,
  'Divider': uiDividerWidget,
  'Button': uiButtonWidget,
  'TextField': uiTextFieldWidget,
  'CheckBox': uiCheckBoxWidget,
  'ChoicePicker': uiChoicePickerWidget,
  'Slider': uiSliderWidget,
  'DateTimeInput': uiDateTimeWidget,
};
