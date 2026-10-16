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
''';
