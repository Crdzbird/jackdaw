/// Default rules for the classes jackdaw_dom gives its elements. Add them
/// to the page once, extend them or replace them.
const String uiDomStyles = '''
.jd-column { display: flex; flex-direction: column; gap: 8px; }
.jd-column[data-align="start"] { align-items: flex-start; }
.jd-column[data-align="center"] { align-items: center; }
.jd-column[data-align="end"] { align-items: flex-end; }
.jd-row { display: flex; flex-direction: row; gap: 8px; align-items: center; }
.jd-scroll { overflow-x: auto; }
.jd-card { border: 1px solid #c4c7c5; border-radius: 12px; padding: 4px; }
.jd-text { margin: 0; }
.jd-caption { font-size: 0.8em; opacity: 0.8; }
.jd-divider { border: 0; border-top: 1px solid #c4c7c5; margin: 8px 0; }
.jd-vertical { border-top: 0; border-left: 1px solid #c4c7c5; height: 24px; }
.jd-field, .jd-slider { display: flex; flex-direction: column; gap: 4px; }
.jd-check { display: flex; flex-direction: row; gap: 8px; align-items: center; }
.jd-error { color: #b3261e; }
.jd-error:empty { display: none; }
.jd-image { display: inline-block; max-width: 100%; }
.jd-image img { display: block; width: 100%; height: 160px; object-fit: fill; }
.jd-image[data-fit="contain"] img { object-fit: contain; }
.jd-image[data-fit="cover"] img { object-fit: cover; }
.jd-image[data-fit="none"] img { object-fit: none; }
.jd-image[data-fit="scaleDown"] img { object-fit: scale-down; }
.jd-image[data-variant="icon"] img { width: 24px; height: 24px; }
.jd-image[data-variant="avatar"] img { width: 40px; height: 40px; border-radius: 50%; }
.jd-image[data-variant="smallFeature"] img { width: 64px; height: 64px; }
.jd-image[data-variant="largeFeature"] img { height: 240px; }
.jd-image[data-variant="header"] img { height: 200px; }
.jd-icon { display: inline-flex; width: 24px; height: 24px; }
.jd-icon svg { width: 100%; height: 100%; fill: currentColor; }
.jd-media { display: flex; flex-direction: column; gap: 4px; }
.jd-media video { max-width: 100%; }
.jd-tab-bar { display: flex; gap: 4px; overflow-x: auto; border-bottom: 1px solid #c4c7c5; }
.jd-tab { border: 0; background: none; padding: 8px 12px; cursor: pointer; }
.jd-tab[aria-selected="true"] { border-bottom: 2px solid currentColor; }
.jd-modal-trigger { cursor: pointer; }
.jd-dialog { border: 0; border-radius: 12px; padding: 16px; }
.jd-choices { border: 0; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 4px; }
.jd-choice { display: flex; gap: 8px; align-items: center; }
.jd-chips { flex-direction: row; flex-wrap: wrap; gap: 8px; }
.jd-chips legend { width: 100%; }
.jd-chips .jd-choice { border: 1px solid #c4c7c5; border-radius: 8px; padding: 4px 12px; }
.jd-chips .jd-choice input { position: absolute; opacity: 0; }
.jd-chips .jd-choice:has(input:checked) { background: #e8def8; }
''';
