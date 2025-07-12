import 'package:flutter/material.dart';

class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  _DocsScreenState createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF16213E), Color(0xFF0F3460)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'DOCS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
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
                        colors: [Color(0xFF0F3460), Color(0xFF533483)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
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
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.library_books,
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
                                    'Technical Documentation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Aircraft maintenance manuals and guides',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Search Section
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xFF0F3460)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Color(0xFF533483),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Search Documents',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search documents...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.search, color: Color(0xFF533483)),
                              filled: true,
                              fillColor: Color(0xFF0F3460),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Documents Section
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xFF0F3460)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.folder,
                                color: Color(0xFF533483),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Available Documents',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          
                          // Documents List
                          _buildDocumentItem(
                            title: 'A320 Maintenance Manual',
                            size: '15.2 MB',
                            modified: '2024-01-15',
                            category: 'Maintenance',
                            icon: Icons.build,
                            categoryColor: Color(0xFF48BB78),
                          ),
                          
                          SizedBox(height: 12),
                          
                          _buildDocumentItem(
                            title: 'Panel Inspection Procedures',
                            size: '8.7 MB',
                            modified: '2024-01-12',
                            category: 'Procedures',
                            icon: Icons.assignment,
                            categoryColor: Color(0xFF667eea),
                          ),
                          
                          SizedBox(height: 12),
                          
                          _buildDocumentItem(
                            title: 'Safety Guidelines v2.1',
                            size: '4.3 MB',
                            modified: '2024-01-10',
                            category: 'Safety',
                            icon: Icons.security,
                            categoryColor: Color(0xFFFF9800),
                          ),
                          
                          SizedBox(height: 12),
                          
                          _buildDocumentItem(
                            title: 'Aircraft Systems Overview',
                            size: '12.5 MB',
                            modified: '2024-01-08',
                            category: 'Technical',
                            icon: Icons.settings,
                            categoryColor: Color(0xFF9C27B0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Quick Actions Section
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(0xFF0F3460)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.flash_on,
                                color: Color(0xFF533483),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionButton(
                                  icon: Icons.download,
                                  title: 'Download All',
                                  subtitle: 'Offline access',
                                  onTap: () {},
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionButton(
                                  icon: Icons.sync,
                                  title: 'Sync Updates',
                                  subtitle: 'Check updates',
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildDocumentItem({
    required String title,
    required String size,
    required String modified,
    required String category,
    required IconData icon,
    required Color categoryColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF1A1A2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Row: Icon and Title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: categoryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              // Wrap title with Expanded to prevent overflow
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(width: 8), // Add spacing before download icon
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF533483), Color(0xFF0F3460)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Second Row: Category and Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: categoryColor,
                  ),
                ),
              ),
              Text(
                '$size • $modified',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF533483), Color(0xFF0F3460)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}