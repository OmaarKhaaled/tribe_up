import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:logging/logging.dart' as app_logging;
import 'package:signalr_netcore/signalr_client.dart';
import 'package:tribe_up/core/constants/api_constants.dart';
import 'package:tribe_up/core/services/secure_storage_service.dart';
import 'package:tribe_up/features/groups/data/models/chat_message_model.dart';
import 'package:tribe_up/features/groups/domain/entities/chat_message_entity.dart';

/// Connection status of the SignalR group-chat hub.
enum SignalRConnectionStatus { disconnected, connecting, connected, error }

/// Manages the real-time connection to the `/hubs/group-chat` SignalR hub.
///
/// Handles:
/// - `ReceiveGroupMessage`  — new message in the group
/// - `ReceiveMessageEdit`   — a message was edited
/// - `UpdateInbox`          — inbox list should refresh

class UpdateInboxPayload {
  final int groupId;
  final String lastMessage;
  final DateTime sentAt;
  UpdateInboxPayload({
    required this.groupId,
    required this.lastMessage,
    required this.sentAt,
  });
}

@lazySingleton
class GroupChatSignalRService {
  final SecureStorageService _secureStorageService;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  GroupChatSignalRService(this._secureStorageService);

  // ── Hub connection ──────────────────────────────────────────────────────────
  HubConnection? _connection;
  SignalRConnectionStatus _status = SignalRConnectionStatus.disconnected;
  bool _intentionalDisconnect = false;
  int? _currentGroupId;

  SignalRConnectionStatus get status => _status;
  bool get isConnected => _status == SignalRConnectionStatus.connected;

  // ── Typed stream controllers ────────────────────────────────────────────────
  final _receiveGroupMessageController =
      StreamController<ChatMessageEntity>.broadcast();
  final _receiveMessageEditController =
      StreamController<ChatMessageEntity>.broadcast();
  final _receiveMessageDeletionController = StreamController<int>.broadcast();
  final _updateInboxController =
      StreamController<UpdateInboxPayload>.broadcast();

  // ── Public streams ──────────────────────────────────────────────────────────

  /// Fires when a new group message arrives in real time.
  Stream<ChatMessageEntity> get onReceiveGroupMessage =>
      _receiveGroupMessageController.stream;

  /// Fires when an existing message is edited.
  Stream<ChatMessageEntity> get onReceiveMessageEdit =>
      _receiveMessageEditController.stream;

  /// Fires when a message is deleted; emits the deleted message ID.
  Stream<int> get onReceiveMessageDeletion =>
      _receiveMessageDeletionController.stream;

  /// Fires when the inbox should be refreshed.
  Stream<UpdateInboxPayload> get onUpdateInbox => _updateInboxController.stream;

  // ── Connect / Disconnect ────────────────────────────────────────────────────

  Future<void> connect() async {
    if (_status == SignalRConnectionStatus.connected ||
        _status == SignalRConnectionStatus.connecting) {
      _logger.d('[GroupChatSignalR] Already connected or connecting — skip.');
      return;
    }

    _logger.d('[GroupChatSignalR] Transition → CONNECTING');
    _status = SignalRConnectionStatus.connecting;

    try {
      // Strip any "Bearer " prefix — SignalR client adds it automatically.
      final rawToken = await _secureStorageService.getToken() ?? '';
      final token = rawToken.startsWith('Bearer ')
          ? rawToken.substring(7)
          : rawToken;

      _logger.d('[GroupChatSignalR] Token present: ${token.isNotEmpty}');

      // skipNegotiation=true + WebSockets bypasses the /negotiate call that was
      // failing with a server timeout on Azure App Service.
      _connection =
          HubConnectionBuilder()
              .withUrl(
                '${ApiConstants.hubBaseUrl}${ApiConstants.groupChatHubPath}',
                options: HttpConnectionOptions(
                  accessTokenFactory: () async {
                    final raw = await _secureStorageService.getToken() ?? '';
                    return raw.startsWith('Bearer ') ? raw.substring(7) : raw;
                  },
                  transport: HttpTransportType.WebSockets,
                  skipNegotiation: true,
                  requestTimeout: 30000,
                  logger: app_logging.Logger('SignalR'),
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

      // ── Register server → client handlers ──────────────────────────────────
      _connection!.on('ReceiveGroupMessage', _handleReceiveGroupMessage);
      _connection!.on('ReceiveMessageEdit', _handleReceiveMessageEdit);
      _connection!.on('ReceiveMessageDeletion', _handleReceiveMessageDeletion);
      _connection!.on('UpdateInbox', _handleUpdateInbox);

      // ── Lifecycle callbacks ────────────────────────────────────────────────
      _connection!.onclose(({Exception? error}) async {
        _status = SignalRConnectionStatus.disconnected;
        if (_intentionalDisconnect) {
          _intentionalDisconnect = false;
          _logger.i(
            '[GroupChatSignalR] Intentional disconnect, not reconnecting.',
          );
          return;
        }
        _logger.w(
          '[GroupChatSignalR] Connection closed: $error – will retry in 5 s.',
        );
        await Future.delayed(const Duration(seconds: 5));
        await connect();
      });
      _connection!.onreconnecting(
        ({Exception? error}) => _onReconnecting(error),
      );
      _connection!.onreconnected(
        ({String? connectionId}) => _onReconnected(connectionId),
      );

      await _connection!.start();
      _status = SignalRConnectionStatus.connected;
      _logger.i('[GroupChatSignalR] ✅ Connected to group-chat hub.');
    } on Exception catch (e, st) {
      _status = SignalRConnectionStatus.error;
      _connection = null;
      if (e.toString().contains('401')) {
        _logger.e(
          '[GroupChatSignalR] 401 – token missing or invalid.',
          error: e,
          stackTrace: st,
        );
      } else {
        _logger.e(
          '[GroupChatSignalR] Connection failed.',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  Future<void> disconnect() async {
    if (_connection == null) return;
    _intentionalDisconnect = true;
    try {
      if (_currentGroupId != null) {
        await leaveGroupChat(_currentGroupId!);
      }
      await _connection!.stop();
      _logger.i('[GroupChatSignalR] Disconnected from group-chat hub.');
    } catch (e) {
      _logger.w('[GroupChatSignalR] Error during disconnect: $e');
    } finally {
      _status = SignalRConnectionStatus.disconnected;
      _connection = null;
    }
  }

  Future<void> joinGroupChat(int groupId) async {
    _currentGroupId = groupId;
    if (_connection == null || _status != SignalRConnectionStatus.connected) {
      _logger.w(
        '[GroupChatSignalR] Cannot join group $groupId: Not connected.',
      );
      return;
    }
    try {
      await _connection!.invoke('JoinGroupChat', args: [groupId]);
      _logger.i('[GroupChatSignalR] ✅ Joined group $groupId');
    } catch (e) {
      _logger.e('[GroupChatSignalR] ⛔ Error joining group $groupId: $e');
    }
  }

  Future<void> leaveGroupChat(int groupId) async {
    if (_currentGroupId == groupId) {
      _currentGroupId = null;
    }
    if (_connection == null || _status != SignalRConnectionStatus.connected) {
      return;
    }
    try {
      await _connection!.invoke('LeaveGroupChat', args: [groupId]);
      _logger.i('[GroupChatSignalR] ✅ Left group $groupId');
    } catch (e) {
      _logger.w('[GroupChatSignalR] ⛔ Error leaving group $groupId: $e');
    }
  }

  // ── Lifecycle callbacks ─────────────────────────────────────────────────────

  void _onReconnecting(Exception? error) {
    _status = SignalRConnectionStatus.connecting;
    _logger.w('[GroupChatSignalR] Reconnecting… error: $error');
  }

  void _onReconnected(String? connectionId) {
    _status = SignalRConnectionStatus.connected;

    // print('[SignalR] RECONNECTED: $connectionId');

    _logger.i('[GroupChatSignalR] Reconnected. connectionId=$connectionId');

    if (_currentGroupId != null) {
      joinGroupChat(_currentGroupId!);
    }
  }

  // ── Event handlers ──────────────────────────────────────────────────────────

  // void _handleReceiveGroupMessage(List<Object?>? args) {
  //   try {
  //     final raw = args?.first;
  //     if (raw == null) return;
  //     final map = Map<String, dynamic>.from(raw as Map);
  //     final entity = ChatMessageModel.fromJson(map).toEntity();
  //     _receiveGroupMessageController.add(entity);
  //     _logger.d('[GroupChatSignalR] ReceiveGroupMessage → id=${entity.id}');
  //   } catch (e) {
  //     _logger.e('[GroupChatSignalR] Error parsing ReceiveGroupMessage: $e');
  //   }
  // }
  void _handleReceiveGroupMessage(List<Object?>? args) {
    try {
      _logger.i(
        '[SignalR] ReceiveGroupMessage fired. Args count: ${args?.length ?? 0}',
      );

      final raw = args?.first;

      if (raw == null) {
        _logger.w('[SignalR] ReceiveGroupMessage received NULL payload');
        return;
      }

      _logger.i('[SignalR] Raw payload: $raw');

      final map = Map<String, dynamic>.from(raw as Map);

      _logger.i('[SignalR] Parsed map: $map');

      final entity = ChatMessageModel.fromJson(map).toEntity();

      _logger.i(
        '[SignalR] Parsed message successfully. '
        'id=${entity.id}, '
        'groupId=${entity.groupId}, '
        'sender=${entity.senderName}',
      );

      _receiveGroupMessageController.add(entity);

      _logger.i('[SignalR] Message pushed to stream. id=${entity.id}');
    } catch (e, stackTrace) {
      _logger.e('[SignalR] Error parsing ReceiveGroupMessage: $e\n$stackTrace');
    }
  }

  void _handleReceiveMessageEdit(List<Object?>? args) {
    try {
      final raw = args?.first;
      if (raw == null) return;
      final map = Map<String, dynamic>.from(raw as Map);
      _logger.i('[GroupChatSignalR] Raw Edit Payload: $map');

      // If backend sends `messageId` instead of `id`
      if (!map.containsKey('id') && map.containsKey('messageId')) {
        map['id'] = map['messageId'];
      }
      // Force isEdited to true since it came from the edit stream
      map['isEdited'] = true;

      final entity = ChatMessageModel.fromJson(map).toEntity();
      _receiveMessageEditController.add(entity);
      _logger.d('[GroupChatSignalR] ReceiveMessageEdit → id=${entity.id}');
    } catch (e, stackTrace) {
      _logger.e(
        '[GroupChatSignalR] Error parsing ReceiveMessageEdit: $e\n$stackTrace',
      );
    }
  }

  void _handleReceiveMessageDeletion(List<Object?>? args) {
    try {
      final raw = args?.first;
      if (raw == null) return;
      _logger.i('[GroupChatSignalR] Raw Deletion Payload: $raw');

      int? messageId;
      if (raw is int) {
        messageId = raw;
      } else if (raw is num) {
        messageId = raw.toInt();
      } else if (raw is String) {
        messageId = int.tryParse(raw);
      } else if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final val = map['messageId'] ?? map['id'];
        if (val is int) {
          messageId = val;
        } else if (val is num) {
          messageId = val.toInt();
        } else if (val is String) {
          messageId = int.tryParse(val);
        }
      }

      if (messageId == null) return;
      _receiveMessageDeletionController.add(messageId);
      _logger.d(
        '[GroupChatSignalR] ReceiveMessageDeletion → messageId=$messageId',
      );
    } catch (e, stackTrace) {
      _logger.e(
        '[GroupChatSignalR] Error parsing ReceiveMessageDeletion: $e\n$stackTrace',
      );
    }
  }

  void _handleUpdateInbox(List<Object?>? args) {
    try {
      final raw = args?.first;
      if (raw == null) return;
      final map = Map<String, dynamic>.from(raw as Map);

      final groupId = map['groupId'] as int? ?? map['GroupId'] as int?;
      final lastMessage =
          map['lastMessage'] as String? ?? map['LastMessage'] as String?;
      final sentAtStr = map['sentAt'] as String? ?? map['SentAt'] as String?;

      if (groupId != null && lastMessage != null && sentAtStr != null) {
        final sentAt = DateTime.parse(sentAtStr);
        _updateInboxController.add(
          UpdateInboxPayload(
            groupId: groupId,
            lastMessage: lastMessage,
            sentAt: sentAt,
          ),
        );
        _logger.d('[GroupChatSignalR] UpdateInbox received for group $groupId');
      } else {
        _logger.w('[GroupChatSignalR] UpdateInbox missing fields: $map');
      }
    } catch (e) {
      _logger.e('[GroupChatSignalR] Error parsing UpdateInbox: $e');
    }
  }

  // ── Dispose ─────────────────────────────────────────────────────────────────

  @disposeMethod
  Future<void> dispose() async {
    await disconnect();
    await _receiveGroupMessageController.close();
    await _receiveMessageEditController.close();
    await _receiveMessageDeletionController.close();
    await _updateInboxController.close();
  }
}
