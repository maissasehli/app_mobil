import 'dart:io';
import 'package:airbus_app/extnot/utils/network_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Add your API key here - make sure it matches the one in your Flask backend
const String API_KEY = 'your_secure_api_key'; // Change this to match your backend

Future<void> compareImages(
  BuildContext context,
  File? selectedImage1,
  File? selectedImage2,
  Function(bool) setAnalyzing,
  Function(String?, String?, String?, double?, String?) updateResults,
) async {
  if (selectedImage1 == null || selectedImage2 == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please select both images'),
        backgroundColor: Color(0xFFFF9800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return;
  }
  
  // Add the missing debug dialog function
  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Debug Info'),
          content: Text('No backend connection detected. Please check your network or backend server settings.'),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String? activeBackendUrl;
  bool isConnected = false;

  // Try to reconnect if no active backend
  await checkConnectivityAndBackend(context, (bool connected, String? url) {
    isConnected = connected;
    activeBackendUrl = url;
  });

  // If still no connection, try direct connection test
  if (activeBackendUrl == null) {
    await testDirectConnection((bool connected, String? url) {
      isConnected = connected;
      activeBackendUrl = url;
    });
  }

  if (activeBackendUrl == null) {
    setAnalyzing(false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot establish connection to backend server'),
        backgroundColor: Colors.red,
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
    return;
  }

  setAnalyzing(true);
  updateResults(null, null, null, null, null);

  // Create a custom HTTP client with longer timeout and better connection handling
  final client = http.Client();
  
  try {
    print('=== Starting image comparison ===');
    print('Using backend: $activeBackendUrl');

    // Check file sizes first
    final file1Size = await selectedImage1.length();
    final file2Size = await selectedImage2.length();
    print('Image 1 size: ${(file1Size / (1024 * 1024)).toStringAsFixed(2)} MB');
    print('Image 2 size: ${(file2Size / (1024 * 1024)).toStringAsFixed(2)} MB');

    if (file1Size > 16 * 1024 * 1024 || file2Size > 16 * 1024 * 1024) {
      throw Exception('Image size exceeds 16MB limit');
    }

    // Create multipart request
    var request = http.MultipartRequest('POST', Uri.parse('$activeBackendUrl/compare_images'));

    // Add headers with proper connection handling
    request.headers['Accept'] = 'application/json';
    request.headers['X-API-Key'] = API_KEY;
    request.headers['Connection'] = 'keep-alive';
    request.headers['Accept-Encoding'] = 'gzip, deflate';

    // Add files
    request.files.add(await http.MultipartFile.fromPath(
      'image1',
      selectedImage1.path,
      filename: 'image1.jpg',
    ));
    request.files.add(await http.MultipartFile.fromPath(
      'image2',
      selectedImage2.path,
      filename: 'image2.jpg',
    ));

    // Add parameters - use lower sensitivity for faster processing
    request.fields['sensitivity'] = '30'; // Slightly higher threshold
    request.fields['min_area'] = '50'; // Larger minimum area
    request.fields['align'] = 'true';
    request.fields['alignment_method'] = 'phase';

    print('Sending comparison request with API key...');

    // Send request with extended timeout and retry logic
    http.StreamedResponse? streamedResponse;
    int retryCount = 0;
    const int maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        streamedResponse = await client.send(request).timeout(
          Duration(seconds: 180), // Extended timeout to 3 minutes
          onTimeout: () {
            throw Exception('Request timed out after 3 minutes');
          },
        );
        break; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        print('Attempt $retryCount failed: $e');
        
        if (retryCount >= maxRetries) {
          rethrow;
        }
        
        // Wait before retry
        await Future.delayed(Duration(seconds: 2));
        
        // Recreate request for retry
        request = http.MultipartRequest('POST', Uri.parse('$activeBackendUrl/compare_images'));
        request.headers['Accept'] = 'application/json';
        request.headers['X-API-Key'] = API_KEY;
        request.headers['Connection'] = 'keep-alive';
        request.headers['Accept-Encoding'] = 'gzip, deflate';
        
        request.files.add(await http.MultipartFile.fromPath(
          'image1',
          selectedImage1.path,
          filename: 'image1.jpg',
        ));
        request.files.add(await http.MultipartFile.fromPath(
          'image2',
          selectedImage2.path,
          filename: 'image2.jpg',
        ));
        
        request.fields['sensitivity'] = '30';
        request.fields['min_area'] = '50';
        request.fields['align'] = 'true';
        request.fields['alignment_method'] = 'phase';
      }
    }

    if (streamedResponse == null) {
      throw Exception('Failed to get response after $maxRetries attempts');
    }

    print('Response status: ${streamedResponse.statusCode}');
    print('Response content length: ${streamedResponse.contentLength}');

    // Read response in chunks to handle large responses
    final responseData = <int>[];
    await for (List<int> chunk in streamedResponse.stream) {
      responseData.addAll(chunk);
      // Optional: Show progress for large responses
      if (responseData.length % (1024 * 1024) == 0) {
        print('Downloaded ${(responseData.length / (1024 * 1024)).toStringAsFixed(1)} MB');
      }
    }

    final response = http.Response.bytes(responseData, streamedResponse.statusCode);
    print('Total response size: ${(response.bodyBytes.length / (1024 * 1024)).toStringAsFixed(2)} MB');

    if (response.statusCode == 200) {
      try {
        var jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          updateResults(
            jsonResponse['results']['difference_image'],
            jsonResponse['results']['original_image1'],
            jsonResponse['results']['original_image2'],
            jsonResponse['results']['difference_percentage']?.toDouble(),
            jsonResponse['analysis_id'],
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image comparison completed successfully!'),
              backgroundColor: Color(0xFF48BB78),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          throw Exception(jsonResponse['error'] ?? 'Unknown error');
        }
      } catch (e) {
        print('JSON parsing error: $e');
        print('Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        throw Exception('Failed to parse server response');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Authentication failed - check API key');
    } else if (response.statusCode == 413) {
      throw Exception('Images too large - maximum size is 16MB');
    } else {
      print('Server error response: ${response.body}');
      throw Exception('Server error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Comparison failed: $e');

    String errorMessage = 'Comparison failed: ${e.toString()}';
    
    if (e.toString().contains('403') || e.toString().contains('Authentication failed')) {
      errorMessage = 'Authentication failed - check API key configuration';
    } else if (e.toString().contains('Connection closed')) {
      errorMessage = 'Connection lost during transfer - try with smaller images';
    } else if (e.toString().contains('timed out')) {
      errorMessage = 'Request timed out - images might be too large or complex';
    } else if (e.toString().contains('413') || e.toString().contains('too large')) {
      errorMessage = 'Images too large - maximum size is 16MB each';
    } else if (e.toString().contains('Broken pipe')) {
      errorMessage = 'Connection lost - please try again';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => compareImages(context, selectedImage1, selectedImage2, setAnalyzing, updateResults),
        ),
      ),
    );
  } finally {
    client.close();
    setAnalyzing(false);
  }
}