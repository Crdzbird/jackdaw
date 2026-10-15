import 'gallery_display.dart';
import 'gallery_inputs.dart';

/// Every component of the basic catalog on one surface, as a tree.
const Map<String, Object?> gallery = {
  'surfaceId': 'gallery',
  'root': {
    'component': 'Column',
    'children': [...galleryDisplay, ...galleryInputs],
  },
  'dataModel': {
    'email': 'ana@example.com',
    'subscribe': true,
    'size': ['l'],
    'volume': 4,
    'date': '2026-01-16',
  },
};
