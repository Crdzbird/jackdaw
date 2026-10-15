/// What the app lets generated UI do outside the surface.
final class UiHost {
  /// Creates a host that opens links with [openUrl] when [allowUrl]
  /// accepts them.
  const factory({
    bool Function(Uri url)? allowUrl,
    void Function(Uri url)? openUrl,
  }) = UiHost._;

  const new _({this.allowUrl, this.openUrl});

  /// Whether a link may be opened; links are refused when unset.
  final bool Function(Uri url)? allowUrl;

  /// Opens a link the user asked for.
  final void Function(Uri url)? openUrl;
}
