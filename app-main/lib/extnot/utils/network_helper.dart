
import 'package:airbus_app/extnot/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> checkConnectivityAndBackend(
  BuildContext context,
  Function(bool, String?) updateConnectionState,
) async {
  print('=== Starting connectivity check ===');

  // Check network connectivity first
  var connectivityResult = await Connectivity().checkConnectivity();
  print('Network connectivity: $connectivityResult');

  if (connectivityResult == ConnectivityResult.none) {
    updateConnectionState(false, null);
    _showConnectionError(context, "No internet connection detected");
    return;
  }

  // Test each backend URL with detailed logging
  for (String url in Constants.BACKEND_URLS) {
    print('--- Testing backend: $url ---');

    try {
      // First, try a simple HTTP client test
      final client = http.Client();

      print('Attempting connection to: $url/health');

      final response = await client.get(
        Uri.parse('$url/health'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Flutter-App/1.0',
        },
      ).timeout(
        Duration(seconds: 8),
        onTimeout: () {
          print('Timeout occurred for $url');
          throw Exception('Connection timeout');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        updateConnectionState(true, url);
        print('✅ Successfully connected to: $url');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to backend server'),
            backgroundColor: Color(0xFF48BB78),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 2),
          ),
        );

        client.close();
        return;
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }

      client.close();
    } catch (e) {
      print('❌ Connection failed for $url: $e');

      // Check for specific error types
      if (e.toString().contains('Connection refused')) {
        print('  → Server is not running or port is blocked');
      } else if (e.toString().contains('timeout')) {
        print('  → Connection timed out');
      } else if (e.toString().contains('No route to host')) {
        print('  → Network routing issue');
      } else if (e.toString().contains('Network is unreachable')) {
        print('  → Network connectivity issue');
      }
    }
  }

  // If no backend is available
  print('❌ No backend server available');
  updateConnectionState(false, null);
  _showConnectionError(context, "Cannot connect to any backend server");
}

void _showConnectionError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Tested URLs: ${Constants.BACKEND_URLS.join(', ')}',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 8),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      action: SnackBarAction(
        label: 'Debug',
        textColor: Colors.white,
        onPressed: () => _showDebugDialog(context),
      ),
    ),
  );
}

void _showDebugDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Network Debug Information'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Backend URLs being tested:'),
            SizedBox(height: 8),
            ...Constants.BACKEND_URLS.map((url) => Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 4),
                  child: Text('• $url', style: TextStyle(fontFamily: 'monospace')),
                )),
            SizedBox(height: 16),
            Text('Current Status:'),
            SizedBox(height: 8),
            Text('• Connected: Not available in this context'),
            Text('• Active URL: Not available in this context'),
            SizedBox(height: 16),
            Text('Troubleshooting Steps:'),
            SizedBox(height: 8),
            Text('1. Make sure your backend server is running'),
            Text('2. Check if the server is listening on the correct port'),
            Text('3. Verify your device and server are on the same network'),
            Text('4. For Android emulator, use 10.0.2.2'),
            Text('5. For iOS simulator, use localhost or 127.0.0.1'),
            Text('6. For physical device, use your computer\'s IP address'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            checkConnectivityAndBackend(context, (bool connected, String? url) {});
          },
          child: Text('Retry'),
        ),
      ],
    ),
  );
}

Future<void> testDirectConnection(
  Function(bool, String?) updateConnectionState,
) async {
  print('=== Testing direct connection ===');

  for (String url in Constants.BACKEND_URLS) {
    print('Testing direct connection to: $url');

    try {
      // Try to connect to the root endpoint
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 5));

      print('Direct connection status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 404) {
        // Even 404 means the server is responding
        updateConnectionState(true, url);
        print('✅ Server is responding at: $url');
        return;
      }
    } catch (e) {
      print('❌ Direct connection failed: $e');
    }
  }

  print('❌ No server responding on any URL');
}
