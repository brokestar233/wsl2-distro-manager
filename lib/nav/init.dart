import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:localization/localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wsl2distromanager/api/wsl.dart';
import 'package:wsl2distromanager/components/constants.dart';
import 'package:wsl2distromanager/components/helpers.dart';
import 'package:wsl2distromanager/components/notify.dart';
import 'package:wsl2distromanager/dialogs/changelog_dialog.dart';
import 'package:wsl2distromanager/dialogs/firststart_dialog.dart';

initRoot(statusMsg) async {
  // Call constructor to initialize
  Notify();
  Notify.message = statusMsg;

  await initPrefs();
  // First start with this version
  String? version = prefs.getString('version');

  if (version == null) {
    // First start
    prefs.setString('version', currentVersion);
    firststartDialog();
  } else if (version != currentVersion) {
    // First start with this version
    prefs.setString('version', currentVersion);

    // Get changelog
    var response = await Dio().get(updateUrl);
    if (response.data.length > 0) {
      var latest = response.data[0];
      String tagName = latest['tag_name'];
      String body = latest['body'];

      changelogDialog(prefs, tagName, body);
    }
  }
  if (kDebugMode) {
    // prefs.remove('version');
  }
  // Check updates
  App app = App();
  app.checkUpdate(currentVersion).then((updateUrl) {
    if (updateUrl != '') {
      statusMsg('',
          useWidget: true,
          widget: RichText(
              text: TextSpan(children: [
            TextSpan(
                text: '${'newversion-text'.i18n()} ',
                style: const TextStyle(fontSize: 14.0)),
            TextSpan(
                text: '${'downloadnow-text'.i18n()} ',
                style: TextStyle(
                    color: Colors.purple,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrl(Uri.parse(updateUrl))),
            TextSpan(
                text: '${'orcheck-text'.i18n()} ',
                style: const TextStyle(fontSize: 14.0)),
            TextSpan(
                text: '${'windowsstore-text'.i18n()} ',
                style: TextStyle(
                    color: Colors.purple,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrl(Uri.parse(windowsStoreUrl))),
          ])));
    }
  });

  // Check motd Show once a day
  if (prefs.getString('LastMotd') !=
      DateTime.now().toString().substring(0, 10)) {
    prefs.setString('LastMotd', DateTime.now().toString().substring(0, 10));
    app.checkMotd().then((String motd) {
      if (motd != '') {
        Notify.message(motd, duration: const Duration(seconds: 60));
      }
    });
  }

  if (kDebugMode) {
    prefs.remove('LastMotd');
  }
}