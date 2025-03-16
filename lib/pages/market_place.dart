import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/services.dart';
import 'listing_details_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedCategory = "All";
  bool _isLoading = false;

  // Form controllers for adding/editing listings
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  String _category = "Grains";
  bool _isSold = false;
  String? _listingId;
  XFile? _selectedImage;
  String? _imageUrl;
  bool _isUploading = false;

  late CloudinaryPublic _cloudinary;

  @override
  void initState() {
    super.initState();
    final cloudName = "dsbskddgj";
    final uploadPreset = "farmit_upload";
    _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      _showSnackBar("Error picking image: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<String?> _uploadImageToCloudinary(XFile image) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      _showSnackBar("Error uploading image: $e");
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showListingForm({String? listingId}) async {
    setState(() {
      _isLoading = true;
    });

    if (listingId != null) {
      try {
        final doc =
            await _firestore.collection('listings').doc(listingId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _priceController.text = data['price'] ?? '';
          _quantityController.text = data['quantity'] ?? '';
          _locationController.text = data['location'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _category = data['category'] ?? 'Grains';
          _isSold = data['isSold'] ?? false;
          _imageUrl = data['imageUrl'];
          _listingId = listingId;
          _selectedImage = null;
        }
      } catch (e) {
        _showSnackBar("Error loading listing: $e");
      }
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _quantityController.clear();
      _locationController.clear();
      _phoneController.clear();
      _category = "Grains";
      _isSold = false;
      _imageUrl = null;
      _listingId = null;
      _selectedImage = null;
    }

    setState(() {
      _isLoading = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _listingId == null ? "Add New Listing" : "Update Listing",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border:
                                Border.all(color: Colors.grey[300]!, width: 1),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    _selectedImage!.path,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error, size: 40),
                                  ),
                                )
                              : _imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: CachedNetworkImage(
                                        imageUrl: _imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.green[700],
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error, size: 40),
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 40,
                                          color: Colors.green[600],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Add Product Image",
                                          style: TextStyle(
                                            color: Colors.green[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      if (_isUploading)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.green[50],
                            color: Colors.green[600],
                          ),
                        ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _titleController,
                        label: "Title",
                        hint: "Enter product name",
                        icon: Icons.title,
                      ),
                      _buildTextField(
                        controller: _descriptionController,
                        label: "Description",
                        hint: "Enter product description",
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      _buildTextField(
                        controller: _priceController,
                        label: "Price",
                        hint: "e.g., ₹45/kg",
                        icon: Icons.currency_rupee,
                      ),
                      _buildTextField(
                        controller: _quantityController,
                        label: "Quantity",
                        hint: "e.g., 1500 kg",
                        icon: Icons.scale,
                      ),
                      _buildTextField(
                        controller: _locationController,
                        label: "Location",
                        hint: "Enter your location",
                        icon: Icons.location_on,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: "Phone Number",
                        hint: "Enter your contact number",
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Category",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: Icon(Icons.keyboard_arrow_down,
                                color: Colors.green[700]),
                            items: ["Grains", "Vegetables", "Fruits", "Pulses"]
                                .map((category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _category = value!;
                              });
                            },
                            validator: (value) => value == null
                                ? "Please select a category"
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            "Mark as Sold",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: _isSold,
                          activeColor: Colors.green[600],
                          onChanged: (value) {
                            setState(() {
                              _isSold = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _listingId == null ? "Add Listing" : "Save Changes",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);

      setState(() {
        _isLoading = true;
      });

      try {
        String? newImageUrl = _imageUrl;
        if (_selectedImage != null) {
          _showSnackBar("Uploading image...");
          newImageUrl = await _uploadImageToCloudinary(_selectedImage!);
          if (newImageUrl == null) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        final userId = _auth.currentUser!.uid;
        final data = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': _priceController.text.trim(),
          'quantity': _quantityController.text.trim(),
          'isSold': _isSold,
          'category': _category,
          'userId': userId,
          'location': _locationController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          if (newImageUrl != null) 'imageUrl': newImageUrl,
        };

        if (_listingId == null) {
          await _firestore.collection('listings').add(data);
          _showSnackBar("Listing added successfully!");
        } else {
          await _firestore.collection('listings').doc(_listingId).update(data);
          _showSnackBar("Listing updated successfully!");
        }
      } catch (e) {
        _showSnackBar("Error: $e");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            ),
            validator: (value) =>
                value!.isEmpty ? "This field is required" : null,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Marketplace",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Buy and sell farm produce directly",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search products...",
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[600]),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.tune, color: Colors.grey[600]),
                                onPressed: () {},
                              ),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
                    child: _buildMarketOverview(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Categories",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryChip(
                                  "All", _selectedCategory == "All"),
                              _buildCategoryChip(
                                  "Grains", _selectedCategory == "Grains"),
                              _buildCategoryChip("Vegetables",
                                  _selectedCategory == "Vegetables"),
                              _buildCategoryChip(
                                  "Fruits", _selectedCategory == "Fruits"),
                              _buildCategoryChip(
                                  "Pulses", _selectedCategory == "Pulses"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Top Listings",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Row(
                            children: [
                              Text(
                                "View All",
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.green[700],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildListings(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Market Trends",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildMarketTrends(),
                      ],
                    ),
                  ),
                ),
                // Add padding at the bottom for the FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showListingForm(),
        backgroundColor: Colors.green[700],
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text(
          "List Your Crop",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMarketOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('listings').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMarketOverviewCard(
            activeListings: "Loading...",
            todaysTrades: "Loading...",
            priceChange: "Loading...",
          );
        }

        if (snapshot.hasError) {
          return _buildMarketOverviewCard(
            activeListings: "Error",
            todaysTrades: "Error",
            priceChange: "Error",
          );
        }

        if (!snapshot.hasData) {
          return _buildMarketOverviewCard(
            activeListings: "0",
            todaysTrades: "0",
            priceChange: "0%",
          );
        }

        final listings = snapshot.data!.docs;
        final activeListings = listings
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['isSold'] == false)
            .length;

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todaysTrades = listings.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['createdAt'] as Timestamp?;
          return createdAt != null && createdAt.toDate().isAfter(todayStart);
        }).length;

        // Placeholder for price change
        final priceChange = "+2.3%";

        return _buildMarketOverviewCard(
          activeListings: activeListings.toString(),
          todaysTrades: todaysTrades.toString(),
          priceChange: priceChange,
        );
      },
    );
  }

  Widget _buildMarketOverviewCard({
    required String activeListings,
    required String todaysTrades,
    required String priceChange,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[500]!, Colors.green[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insert_chart_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Market Overview",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMarketStat(
                icon: Icons.local_offer_outlined,
                title: "Active Listings",
                value: activeListings,
              ),
              _buildMarketStat(
                icon: Icons.swap_horiz,
                title: "Today's Trades",
                value: todaysTrades,
              ),
              _buildMarketStat(
                icon: Icons.trending_up,
                title: "Price Change",
                value: priceChange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        selectedColor: Colors.green[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        elevation: isSelected ? 2 : 0,
        shadowColor:
            isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent,
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = selected ? label : null;
          });
        },
      ),
    );
  }

  Widget _buildListings() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('listings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  color: Colors.green,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error loading listings",
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No listings found"),
              ),
            ),
          );
        }

        final listings = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = data['title']?.toString().toLowerCase() ?? '';
          final categoryMatch = _selectedCategory == "All" ||
              data['category'] == _selectedCategory;
          return title.contains(_searchController.text.toLowerCase()) &&
              categoryMatch;
        }).toList();

        if (listings.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "No listings match your search",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = listings[index];
                final data = doc.data() as Map<String, dynamic>;
                final isPositive =
                    data['change']?.toString().contains("+") ?? true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _buildListingCard(
                    data['title'] ?? "Unknown",
                    data['description'] ?? "No description",
                    data['price'] ?? "N/A",
                    data['change'] ?? "+0.0%",
                    data['quantity'] ?? "N/A",
                    isPositive,
                    doc.id,
                    data['imageUrl'],
                    data,
                  ),
                );
              },
              childCount: listings.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildListingCard(
    String title,
    String description,
    String price,
    String change,
    String quantity,
    bool isPositive,
    String listingId,
    String? imageUrl,
    Map<String, dynamic> data,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailsPage(
              title: title,
              description: description,
              price: price,
              quantity: quantity,
              location: data['location'] ?? 'N/A',
              phoneNumber: data['phoneNumber'] ?? 'N/A',
              category: data['category'] ?? 'N/A',
              isSold: data['isSold'] ?? false,
              imageUrl: imageUrl,
              listingId: listingId,
              userId: data['userId'] ?? '',
              onEdit: () => _showListingForm(listingId: listingId),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.green[600],
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Change
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data['category'] ?? 'N/A',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isPositive
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              change,
                              style: TextStyle(
                                color: isPositive
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Price & Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quantity,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Location & Contact
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['location'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.message_outlined,
                          size: 18,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketTrends() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTrendItem("Rice", "₹45", "+2.3%", true),
          const Divider(height: 30),
          _buildTrendItem("Wheat", "₹32", "-1.5%", false),
          const Divider(height: 30),
          _buildTrendItem("Corn", "₹28", "+2.8%", true),
          const Divider(height: 30),
          _buildTrendItem("Soybeans", "₹52", "+1.2%", true),
          const Divider(height: 30),
          _buildTrendItem("Potatoes", "₹23", "-0.8%", false),
        ],
      ),
    );
  }

  Widget _buildTrendItem(
      String crop, String price, String change, bool isPositive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.grass,
                color: Colors.green[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              crop,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green[700] : Colors.red[700],
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    change,
                    style: TextStyle(
                      color: isPositive ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
