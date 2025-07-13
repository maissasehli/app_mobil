
import 'dart:io';
import 'package:flutter/material.dart';

class ImageContainer extends StatelessWidget {
  final String title;
  final File? image;
  final String imageType;
  final Function(String) onImageSelected;
  final Function(String) onImageCleared;

  const ImageContainer({
    required this.title,
    required this.image,
    required this.imageType,
    required this.onImageSelected,
    required this.onImageCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () => onImageSelected(imageType),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.file(
                            image!,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => onImageCleared(imageType),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tap to select $title',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF667eea),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
