import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';

@pragma('vm:entry-point')
Future<void> brechoFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService({http.Client? client})
    : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  static const sellerChannel = AndroidNotificationChannel(
    'brecho_requests_urgent',
    'Solicitações do brechó',
    description: 'Novas solicitações que precisam de resposta rápida.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  static const buyerChannel = AndroidNotificationChannel(
    'buyer_purchase_updates',
    'Atualizações de compras',
    description: 'Aprovações, recusas e novidades das suas compras.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  final http.Client _client;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenSubscription;

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(brechoFirebaseBackgroundHandler);
  }

  Future<void> activate(BrechoSession session) async {
    await _foregroundSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _initializeLocalNotifications();
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(session, token);
    }
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => _registerToken(session, token),
    );
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const initialization = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings: initialization);
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(sellerChannel);
    await android?.createNotificationChannel(buyerChannel);
    await android?.requestNotificationsPermission();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final type = message.data['type'] ?? '';
    final sellerAlert = type == 'SELLER_REQUEST';
    final channel = sellerAlert ? sellerChannel : buyerChannel;
    await _local.show(
      id: message.messageId?.hashCode ?? DateTime.now().hashCode,
      title: notification?.title ?? message.data['title'] ?? 'Brechó Express',
      body:
          notification?.body ??
          message.data['body'] ??
          'Você tem uma novidade.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: sellerAlert
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.message,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _registerToken(BrechoSession session, String token) async {
    final response = await _client
        .post(
          _baseUri.resolve('notifications/devices'),
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'token': token,
            'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PushNotificationException(
        'Não foi possível registrar notificações (${response.statusCode}).',
      );
    }
  }

  Future<void> close() async {
    await _foregroundSubscription?.cancel();
    await _tokenSubscription?.cancel();
    _client.close();
  }
}

class PushNotificationException implements Exception {
  const PushNotificationException(this.message);
  final String message;
}
