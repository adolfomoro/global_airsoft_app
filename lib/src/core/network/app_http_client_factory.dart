import 'dart:io';

import 'package:global_airsoft_app/src/core/network/constants/app_network_headers.dart';

typedef AppBadCertificateAcceptedCallback =
    void Function(String host, int port);

final class AppHttpClientFactory {
  const AppHttpClientFactory._();

  static HttpClient create({
    bool allowBadCertificates = false,
    AppBadCertificateAcceptedCallback? onBadCertificateAccepted,
  }) {
    final HttpClient client = HttpClient();
    client.userAgent = AppNetworkHeaders.userAgentValue;

    if (allowBadCertificates) {
      client.badCertificateCallback = (
        X509Certificate _,
        String host,
        int port,
      ) {
        onBadCertificateAccepted?.call(host, port);
        return true;
      };
    }

    return client;
  }
}
