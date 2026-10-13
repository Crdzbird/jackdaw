import 'package:jackdaw_mcp/jackdaw_mcp.dart';
import 'package:stream_channel/stream_channel.dart';

import 'bird_server.dart';

/// Starts a [BirdServer] in this isolate and returns a transport to it.
McpTransport linkedBirdServer() {
  final link = StreamChannelController<String>();
  BirdServer(link.foreign);
  return StreamMcpTransport(
    link.local.stream,
    link.local.sink.add,
    onClose: link.local.sink.close,
  );
}

/// Starts a [BirdServer] in this isolate and returns the client end.
StreamChannel<String> birdChannel() {
  final link = StreamChannelController<String>();
  BirdServer(link.foreign);
  return link.local;
}
