import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Calls [handler] on each [type] event of [target].
void uiDomOn(web.EventTarget target, String type, void Function() handler) =>
    target.addEventListener(type, ((web.Event _) => handler()).toJS);
