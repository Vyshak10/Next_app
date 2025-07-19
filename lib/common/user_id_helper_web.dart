// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> getUserId() async {
  return html.window.localStorage['user_id'];
}

Future<void> setUserId(String id) async {
  html.window.localStorage['user_id'] = id;
} 