
import 'package:airbus_app/extnot/utils/image_comparison_helper.dart';
import 'package:airbus_app/extnot/utils/image_picker_helper.dart';
import 'package:airbus_app/extnot/utils/network_helper.dart';
import 'package:airbus_app/extnot/widgets/comparison_viewer.dart';
import 'package:airbus_app/extnot/widgets/image_container.dart';
import 'package:flutter/material.dart';

import 'dart:io';

class ExtnotScreen extends StatefulWidget {
  const ExtnotScreen({Key? key}) : super(key: key);

  @override
  ExtnotScreenState createState() => ExtnotScreenState();
}

class ExtnotScreenState extends State<ExtnotScreen> with TickerProviderStateMixin {
  String? selectedPanelType;
  File? selectedImage1;
  File? selectedImage2;
  bool isAnalyzing = false;
  String? currentImageSelection;
  bool isConnected = true;

  // Analysis results
  String? differenceImageBase64;
  String? originalImage1Base64;
  String? originalImage2Base64;
  String? markedImage1Base64;
  String? markedImage2Base64;
  String? superpositionBase64;
  double? differencePercentage;
  double? similarityScore;
  int? numDifferences;
  String? analysisId;

  // Tab controller for visualization
  late TabController _tabController;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? activeBackendUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();

    // Check connectivity and find working backend
    checkConnectivityAndBackend(context, (bool connected, String? url) {
      setState(() {
        isConnected = connected;
        activeBackendUrl = url;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EXTNOT - Image Comparison',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF8F9FA),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.compare_arrows,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Image Comparison',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Compare two images and find differences',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Image Selection Section
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.image,
                                color: Color(0xFF667eea),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Select Images',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Images in a row for better comparison
                          Row(
                            children: [
                              Expanded(
                                child: ImageContainer(
                                  title: 'First Image',
                                  image: selectedImage1,
                                  imageType: 'image1',
                                  onImageSelected: (imageType) => pickImage(
                                    context,
                                    imageType,
                                    (type) => setState(() => currentImageSelection = type),
                                    (image) => setState(() => selectedImage1 = image),
                                  ),
                                  onImageCleared: (imageType) {
                                    setState(() {
                                      if (imageType == 'image1') {
                                        selectedImage1 = null;
                                      } else {
                                        selectedImage2 = null;
                                      }
                                      differenceImageBase64 = null;
                                      originalImage1Base64 = null;
                                      originalImage2Base64 = null;
                                      differencePercentage = null;
                                      analysisId = null;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ImageContainer(
                                  title: 'Second Image',
                                  image: selectedImage2,
                                  imageType: 'image2',
                                  onImageSelected: (imageType) => pickImage(
                                    context,
                                    imageType,
                                    (type) => setState(() => currentImageSelection = type),
                                    (image) => setState(() => selectedImage2 = image),
                                  ),
                                  onImageCleared: (imageType) {
                                    setState(() {
                                      if (imageType == 'image1') {
                                        selectedImage1 = null;
                                      } else {
                                        selectedImage2 = null;
                                      }
                                      differenceImageBase64 = null;
                                      originalImage1Base64 = null;
                                      originalImage2Base64 = null;
                                      differencePercentage = null;
                                      analysisId = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 32),

                          // Compare Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF667eea).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isAnalyzing
                                  ? null
                                  : () => compareImages(
                                        context,
                                        selectedImage1,
                                        selectedImage2,
                                        (bool analyzing) {
                                          setState(() {
                                            isAnalyzing = analyzing;
                                          });
                                        },
                                        (String? diffImage, String? origImage1,
                                            String? origImage2, double? diffPercent,
                                            String? analysis) {
                                          setState(() {
                                            differenceImageBase64 = diffImage;
                                            originalImage1Base64 = origImage1;
                                            originalImage2Base64 = origImage2;
                                            differencePercentage = diffPercent;
                                            analysisId = analysis;
                                          });
                                        },
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isAnalyzing
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Analyzing...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.compare,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'Compare Images',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Enhanced Comparison Results with Tabs
                if (differenceImageBase64 != null ||
                    selectedImage1 != null ||
                    selectedImage2 != null)
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ComparisonViewer(
                        tabController: _tabController,
                        originalImage1Base64: originalImage1Base64,
                        originalImage2Base64: originalImage2Base64,
                        differenceImageBase64: differenceImageBase64,
                        selectedImage1: selectedImage1,
                        selectedImage2: selectedImage2,
                        differencePercentage: differencePercentage,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}