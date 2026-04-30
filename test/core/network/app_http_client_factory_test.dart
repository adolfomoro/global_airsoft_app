import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/network/app_http_client_factory.dart';
import 'package:global_airsoft_app/src/core/network/constants/app_network_headers.dart';

void main() {
  test('creates HttpClient with the shared hardcoded user agent', () {
    final client = AppHttpClientFactory.create();
    addTearDown(client.close);

    expect(client.userAgent, AppNetworkHeaders.userAgentValue);
  });
}
