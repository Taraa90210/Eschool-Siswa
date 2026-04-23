import 'package:eschool/utils/system/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;

  SocketService() {
    connect();
  }

  void connect() {
    try {
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket?.on('connect', (_) {
        print('Socket connected');
      });

      _socket?.on('disconnect', (_) {
        print('Socket disconnected');
      });

      _socket?.on('connect_error', (error) {
        print('Socket connection error: $error');
      });
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.disconnect();
  }

  bool get isConnected => _socket?.connected ?? false;
}