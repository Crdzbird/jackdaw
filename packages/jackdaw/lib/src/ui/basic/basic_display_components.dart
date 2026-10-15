import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/basic/basic_props.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';

/// The basic catalog's components that show content.
final List<UiComponentDefinition> basicDisplayComponents = [
  UiComponentDefinition(
    name: 'Text',
    description: 'A piece of text.',
    props: ObjectSchema(
      properties: {
        'text': text('The text to show.'),
        'variant': choice('The text style.', ['caption', 'body']),
        'weight': basicWeight,
      },
      required: ['text'],
    ),
  ),
  UiComponentDefinition(
    name: 'Image',
    description: 'An image loaded from a URL.',
    props: ObjectSchema(
      properties: {
        'url': text('The image URL.'),
        'description': text('What the image shows, for screen readers.'),
        'fit': choice('How the image fills its box.', [
          'contain',
          'cover',
          'fill',
          'none',
          'scaleDown',
        ]),
        'variant': choice('The image size and shape.', [
          'icon',
          'avatar',
          'smallFeature',
          'mediumFeature',
          'largeFeature',
          'header',
        ]),
        'weight': basicWeight,
      },
      required: ['url'],
    ),
  ),
  UiComponentDefinition(
    name: 'Icon',
    description: 'A built-in icon, or one drawn from an SVG path.',
    props: ObjectSchema(
      properties: {
        'name': Schema.anyOf([
          Schema.string(enumValues: basicIconNames.split(' ')),
          ObjectSchema(
            properties: {'svgPath': text('The SVG path data.')},
            required: ['svgPath'],
          ),
          UiType.dataBinding.ref(),
        ], description: 'The icon.'),
        'weight': basicWeight,
      },
      required: ['name'],
    ),
  ),
  UiComponentDefinition(
    name: 'Video',
    description: 'A video player.',
    props: ObjectSchema(
      properties: {
        'url': text('The video URL.'),
        'posterUrl': text('An image shown before the video plays.'),
        'weight': basicWeight,
      },
      required: ['url'],
    ),
  ),
  UiComponentDefinition(
    name: 'AudioPlayer',
    description: 'An audio player.',
    props: ObjectSchema(
      properties: {
        'url': text('The audio URL.'),
        'description': text('A title or summary of the audio.'),
        'weight': basicWeight,
      },
      required: ['url'],
    ),
  ),
];
