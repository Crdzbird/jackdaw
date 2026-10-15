import 'dart:ffi';

import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';

/// Whether the loaded libjackdaw renders chats on its worker thread, which
/// libraries before native 0.1.0-dev.6 cannot. A missing function fails
/// to resolve, while a present one rejects the empty call.
final bool nativeChat = () {
  try {
    jackdaw_session_generate_chat(nullptr, 0, nullptr, 0, nullptr);
    return true;
  } on Object {
    return false;
  }
}();
