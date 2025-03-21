import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _serverController = TextEditingController();

  late PermissionStatus _permissionGranted;
  late LocationData _locationData;
  late WebViewController _webViewController;
  var recordingText = '开始记录';

  final MethodChannel nativeChannel = const MethodChannel(
    'com.example.sign_in_life/native_view',
  );

  @override
  void initState() {
    super.initState();
    locationInit();
    initWebViewController();
  }

  Future<void> locationInit() async {
    Location location = Location();

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // nativeChannel.invokeMethod('startLocation');

    _locationData = await location.getLocation();
    _webViewController.runJavaScript(
      'setLocation(${_locationData.latitude}, ${_locationData.longitude})',
    );
    print(
      "Location changed: ${_locationData.latitude}, ${_locationData.longitude}",
    );

    location.onLocationChanged.listen((LocationData currentLocation) {
      _locationData = currentLocation;

      _webViewController.runJavaScript(
        'setLocation(${_locationData.latitude}, ${_locationData.longitude})',
      );
      print(
        "Location changed: ${currentLocation.latitude}, ${currentLocation.longitude}",
      );
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  Widget buildAndroidView(BuildContext context) {
    const String viewType = '<platform-view-type>';
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return Stack(
      children: [
        Positioned.fill(
          child: AndroidView(
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (recordingText == "开始记录") {
                    await nativeChannel.invokeMethod('startRecording');
                    setState(() {
                      recordingText = '停止记录';
                    });
                  } else {
                    await nativeChannel.invokeMethod('stopRecording');
                    setState(() {
                      recordingText = '开始记录';
                    });
                  }
                },
                child: Text(recordingText),
              ),
              ElevatedButton(
                onPressed: () {
                  nativeChannel.invokeListMethod("playbackRecording");
                },
                child: const Text('重放记录'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildMap(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          51.509364,
          -0.128928,
        ), // Center the map over London
        initialZoom: 9.2,
      ),
      children: [
        TileLayer(
          // Bring your own tiles
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
          userAgentPackageName: 'com.example.app', // Add your app identifier
          // And many more recommended properties!
        ),
        RichAttributionWidget(
          // Include a stylish prebuilt attribution widget that meets all requirments
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap:
                  () => launchUrl(
                    Uri.parse('https://openstreetmap.org/copyright'),
                  ), // (external)
            ),
            // Also add images...
          ],
        ),
      ],
    );
  }

  Widget buildWebMap(BuildContext context) {
    return WebViewWidget(controller: _webViewController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Map"),
      ),
      body: Expanded(child: buildAndroidView(context)),
    );
  }

  void initWebViewController() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                // Update loading bar.
              },
              onPageStarted: (String url) {},
              onPageFinished: (String url) {},
              onHttpError: (HttpResponseError error) {},
              onWebResourceError: (WebResourceError error) {},
              onNavigationRequest: (NavigationRequest request) {
                // Handle navigation requests.
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(
            Uri.parse(
              'file:///android_asset/flutter_assets/assets/html/index.html',
            ),
          );
  }
}
