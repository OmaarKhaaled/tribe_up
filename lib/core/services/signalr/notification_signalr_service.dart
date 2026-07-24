import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:logging/logging.dart' as app_logging;
import 'package:signalr_netcore/signalr_client.dart';
import 'package:tribe_up/core/constants/api_constants.dart';
import 'package:tribe_up/core/services/secure_storage_service.dart';
import 'package:tribe_up/features/notification/domain/entities/notification_entity.dart';

/// Manages the real-time connection to the `/hubs/notifications` SignalR hub.
///
/// Handles the `notification-received` server-push event.
@lazySingleton
class NotificationSignalRService {
  final SecureStorageService _secureStorageService;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  NotificationSignalRService(this._secureStorageService);

  HubConnection? _connection;
  bool _isConnected = false;
  bool _intentionalDisconnect = false;

  final _notificationReceivedController =
      StreamController<NotificationEntity>.broadcast();

  /// Fires when a new notification arrives via the notifications hub.
  Stream<NotificationEntity> get onNotificationReceived =>
      _notificationReceivedController.stream;

  Future<void> connect() async {
    if (_isConnected || _connection != null) return;

    try {
      // Strip any "Bearer " prefix — SignalR client adds it automatically.
      final rawToken = await _secureStorageService.getToken() ?? '';
      final token = rawToken.startsWith('Bearer ')
          ? rawToken.substring(7)
          : rawToken;

      _logger.d('[NotifSignalR] Token present: ${token.isNotEmpty}');

      // skipNegotiation=true + WebSockets bypasses the /negotiate call that was
      // failing with a server timeout on Azure App Service.
      _connection =
          HubConnectionBuilder()
              .withUrl(
                '${ApiConstants.hubBaseUrl}${ApiConstants.notificationsHubPath}',
                options: HttpConnectionOptions(
                  accessTokenFactory: () async {
                    final raw = await _secureStorageService.getToken() ?? '';
                    return raw.startsWith('Bearer ') ? raw.substring(7) : raw;
                  },
                  transport: HttpTransportType.WebSockets,
                  skipNegotiation: true,
                  requestTimeout: 30000,
                  logger: app_logging.Logger('NotifSignalR'),
                  logMessageContent: true,
                ),
              )
              .withAutomaticReconnect(
                retryDelays: [0, 2000, 5000, 10000, 30000],
              )
              .build()
            ..serverTimeoutInMilliseconds =
                60000 // 60 s
            ..keepAliveIntervalInMilliseconds = 15000; // Ping every 15 s

      _connection!.on('notification-received', _handleNotificationReceived);

      _connection!.onclose(({Exception? error}) async {
        _isConnected = false;
        if (_intentionalDisconnect) {
          _intentionalDisconnect = false;
          _logger.i('[NotifSignalR] Intentional disconnect, not reconnecting.');
          return;
        }
        _logger.w(
          '[NotifSignalR] Connection closed: $error – will retry in 5 s.',
        );
        await Future.delayed(const Duration(seconds: 5));
        await connect();
      });

      _connection!.onreconnected(({String? connectionId}) {
        _isConnected = true;
        _logger.i('[NotifSignalR] Reconnected: $connectionId');
      });

      await _connection!.start();
      _isConnected = true;
      _logger.i('[NotifSignalR] ✅ Connected to notifications hub.');
    } on Exception catch (e, st) {
      _isConnected = false;
      _connection = null;
      if (e.toString().contains('401')) {
        _logger.e(
          '[NotifSignalR] 401 – token missing or invalid.',
          error: e,
          stackTrace: st,
        );
      } else {
        _logger.e(
          '[NotifSignalR] Connection failed.',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    try {
      await _connection?.stop();
    } catch (_) {}
    _isConnected = false;
    _connection = null;
  }

  void _handleNotificationReceived(List<Object?>? args) {
    try {
      final raw = args?.first;
      if (raw == null) return;
      final map = Map<String, dynamic>.from(raw as Map);

      final entity = NotificationEntity(
        id: map['id'] as int?,
        title: map['title'] as String?,
        message: map['message'] as String?,
        type: map['type'] as String?,
        isRead: map['isRead'] as bool? ?? false,
        createdAt: map['createdAt']?.toString(),
        referenceId: map['referenceId'] as int?,
        actorUserName: map['actorUserName'] as String?,
        actorPicture: map['actorPicture'] as String?,
      );

      _notificationReceivedController.add(entity);
      _logger.d('[NotifSignalR] notification-received → id=${entity.id}');
    } catch (e) {
      _logger.e('[NotifSignalR] Error parsing notification-received: $e');
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    await disconnect();
    await _notificationReceivedController.close();
  }
}
