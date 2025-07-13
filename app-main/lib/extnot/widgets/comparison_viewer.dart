
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class ComparisonViewer extends StatelessWidget {
  final TabController tabController;
  final String? originalImage1Base64;
  final String? originalImage2Base64;
  final String? differenceImageBase64;
  final File? selectedImage1;
  final File? selectedImage2;
  final double? differencePercentage;

  const ComparisonViewer({
    required this.tabController,
    required this.originalImage1Base64,
    required this.originalImage2Base64,
    required this.differenceImageBase64,
    required this.selectedImage1,
    required this.selectedImage2,
    required this.differencePercentage,
  });

  Widget _buildImageView(String? imageBase64, String title, File? originalFile, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Color(0xFF667eea), size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Image Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageBase64 != null
                    ? Image.memory(
                        base64Decode(imageBase64),
                        fit: BoxFit.contain,
                      )
                    : originalFile != null
                        ? Image.file(
                            originalFile,
                            fit: BoxFit.contain,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Color(0xFF667eea).withOpacity(0.5),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No image selected',
                                  style: TextStyle(
                                    color: Color(0xFF667eea).withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifferenceView() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Title and Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare, color: Color(0xFF667eea), size: 20),
              SizedBox(width: 8),
              Text(
                'Difference Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),

          if (differencePercentage != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF667eea).withOpacity(0.1),
                    Color(0xFF764ba2).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${differencePercentage!.toStringAsFixed(1)}% Different',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ),
          ],

          SizedBox(height: 16),

          // Difference Image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: differenceImageBase64 != null
                    ? Image.memory(
                        base64Decode(differenceImageBase64!),
                        fit: BoxFit.contain,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics,
                              size: 48,
                              color: Color(0xFF667eea).withOpacity(0.5),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Compare images to see differences',
                              style: TextStyle(
                                color: Color(0xFF667eea).withOpacity(0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),

          if (differenceImageBase64 != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFF667eea).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF667eea),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'White/bright areas show differences',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 18),
                      SizedBox(width: 8),
                      Text('Image 1'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 18),
                      SizedBox(width: 8),
                      Text('Image 2'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.compare, size: 18),
                      SizedBox(width: 8),
                      Text('Difference'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Container(
            height: 350,
            child: TabBarView(
              controller: tabController,
              children: [
                // Image 1 View
                _buildImageView(
                  originalImage1Base64,
                  'First Image',
                  selectedImage1,
                  Icons.looks_one,
                ),

                // Image 2 View
                _buildImageView(
                  originalImage2Base64,
                  'Second Image',
                  selectedImage2,
                  Icons.looks_two,
                ),

                // Difference View
                _buildDifferenceView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
