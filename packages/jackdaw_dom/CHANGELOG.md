## 1.0.0

- UiDomController and UiDomView: A2UI v1.0 surfaces drawn as plain HTML,
  each component built once and updated in place by the data writes it
  reads.
- UiDomController.applyAll takes `trusted`, which skips jackdaw's
  checks for messages from a source the app fully trusts.
- Builders for all 18 components of the basic catalog, and default
  styles in uiDomStyles.
- The Material icons of the catalog's icon names as SVG paths, converted
  from the font that ships with Flutter.
