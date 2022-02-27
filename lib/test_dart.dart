import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:win32/win32.dart';

const VK_A = 0x41;
const VK_D = 0x44;
enum MqttCurrentConnectionState { IDLE, CONNECTING, CONNECTED, DISCONNECTED, ERROR_WHEN_CONNECTING }

enum MqttSubscriptionState { IDLE, SUBSCRIBED }
Future<void> main() async {
  print('Notepad açıp 1 saniye uyuyacaksın.');
  //ShellExecute(1000, TEXT('open'), TEXT('notepad.exe'), nullptr, nullptr, SW_SHOW);
  //Sleep(1000);
  await prepareMqttClient();
}

late MqttServerClient client;

MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;
Timer? timer;
int temp = 0;

void _subscribeToTopic(String topicName) {
  print('Subscribing to the $topicName topic');
  client.subscribe(topicName, MqttQos.atMostOnce);
  client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
    final recMess = c![0].payload as MqttPublishMessage;
    final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    rotate(int.tryParse(pt)?.toInt());
    print('EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
    print('');
  });
}

void _onSubscribed(String topic) {
  print('Subscription confirmed for topic $topic');
  subscriptionState = MqttSubscriptionState.SUBSCRIBED;
}

void _onDisconnected() {
  print('OnDisconnected client callback - Client disconnection');
  connectionState = MqttCurrentConnectionState.DISCONNECTED;
}

void _onConnected() {
  connectionState = MqttCurrentConnectionState.CONNECTED;
  print('OnConnected client callback - Client connection was sucessful');
}

Future<void> _connectClient() async {
  try {
    print('client connecting....');
    connectionState = MqttCurrentConnectionState.CONNECTING;
    await client.connect('', '');
  } on Exception catch (e) {
    print('client exception - $e');
    connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
    client.disconnect();
  }

  if (client.connectionStatus?.state == MqttConnectionState.connected) {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('client connected');
  } else {
    print('ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
    connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
    client.disconnect();
  }
}

void _setupMqttClient() {
  client = MqttServerClient.withPort('', '', 8883);
  client.secure = true;
  client.securityContext = SecurityContext.defaultContext;
  client.keepAlivePeriod = 20;
  client.onDisconnected = _onDisconnected;
  client.onConnected = _onConnected;
  client.onSubscribed = _onSubscribed;
}

Future<void> prepareMqttClient() async {
  _setupMqttClient();
  await _connectClient();
  _subscribeToTopic('testtopic/1');
  //_publishMessage('Baslangic Mesaji');
}

Future<void> rotate(int? data) async {
  print('0 ve 1 yazdıracaksın');

  if (data == 1) {
    print("1");
    rotateKey(VK_A);
    /*
    kbd.ref.type = INPUT_KEYBOARD;
    kbd.ref.ki.wVk = VK_A;
    var result = SendInput(1, kbd, sizeOf<INPUT>());
    if (result != TRUE) print('Error: ${GetLastError()}');
    */
  } else if (data == 2) {
    print("2");
    rotateKey(VK_D);
  } else {
    print("empty");
    rotateKey(999);
  }
}

Future<void> rotateKey(int key) async {
  final kbd = calloc<INPUT>();
  kbd.ref.type = INPUT_KEYBOARD;
  kbd.ref.ki.wVk = key;
  var result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');
  //sleep(Duration(milliseconds: 100));
  if (temp != key) {
    kbd.ref.ki.wVk = temp;
    var result = SendInput(1, kbd, sizeOf<INPUT>());
    if (result != TRUE) print('Error: ${GetLastError()}');
    kbd.ref.ki.dwFlags = KEYEVENTF_KEYUP;
    result = SendInput(1, kbd, sizeOf<INPUT>());
    if (result != TRUE) print('Error: ${GetLastError()}');
  }

  free(kbd);
  temp = key;
}



/*

kbd.ref.type = INPUT_KEYBOARD;
  kbd.ref.ki.wVk = VK_UP;
  result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  kbd.ref.type = INPUT_KEYBOARD;
  kbd.ref.ki.wVk = VK_NUMPAD1;
  result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  
  print('Sending a right-click mouse event.');
  final mouse = calloc<INPUT>();
  mouse.ref.type = INPUT_MOUSE;
  mouse.ref.mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
  result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  Sleep(1000);
  mouse.ref.mi.dwFlags = MOUSEEVENTF_RIGHTUP;
  result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  free(mouse);

 */