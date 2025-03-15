import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Use image_picker instead of file_picker
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; // For Cloudinary uploads
import 'listing_details_page.dart'; // Import the new details page

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
  String? _listingId; // For editing existing listings
  XFile? _selectedImage; // Use XFile instead of File for web compatibility
  String? _imageUrl; // To store the Cloudinary URL
  bool _isUploading = false; // To show loading state during upload

  // Initialize Cloudinary
  late CloudinaryPublic _cloudinary;

  @override
  void initState() {
    super.initState();
    // Initialize Cloudinary with credentials (replace with your values)
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

  // Pick an image using image_picker
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  // Upload image to Cloudinary and return the URL
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Show dialog to add or edit a listing
  void _showListingForm({String? listingId}) async {
    if (listingId != null) {
      // Fetch existing listing data for editing
      final doc = await _firestore.collection('listings').doc(listingId).get();
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
        _imageUrl = data['imageUrl']; // Load existing image URL
        _listingId = listingId;
        _selectedImage = null; // Reset selected image
      }
    } else {
      // Reset form for new listing
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_listingId == null ? "Add Listing" : "Edit Listing"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: _selectedImage != null
                        ? Image.network(
                            _selectedImage!.path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          )
                        : _imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              )
                            : const Center(
                                child: Text("Tap to select an image")),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a title" : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a description" : null,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration:
                      const InputDecoration(labelText: "Price (e.g., ₹45/kg)"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a price" : null,
                ),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                      labelText: "Quantity (e.g., 1500 kg)"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a quantity" : null,
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: "Location"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a location" : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a phone number" : null,
                ),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: "Category"),
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
                  validator: (value) =>
                      value == null ? "Please select a category" : null,
                ),
                SwitchListTile(
                  title: const Text("Sold"),
                  value: _isSold,
                  onChanged: (value) {
                    setState(() {
                      _isSold = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                String? newImageUrl = _imageUrl;
                if (_selectedImage != null) {
                  newImageUrl = await _uploadImageToCloudinary(_selectedImage!);
                  if (newImageUrl == null) return; // Stop if upload fails
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
                } else {
                  await _firestore
                      .collection('listings')
                      .doc(_listingId)
                      .update(data);
                }
                Navigator.pop(context);
                setState(() {}); // Refresh the page
              }
            },
            child: Text(_listingId == null ? "Add" : "Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search crops...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // Market Overview
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Market Overview",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMarketStat("Active Listings", "1,234"),
                          _buildMarketStat("Today's Trades", "156"),
                          _buildMarketStat("Price Change", "+2.3%"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Categories
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip("All", _selectedCategory == "All"),
                      _buildCategoryChip(
                          "Grains", _selectedCategory == "Grains"),
                      _buildCategoryChip(
                          "Vegetables", _selectedCategory == "Vegetables"),
                      _buildCategoryChip(
                          "Fruits", _selectedCategory == "Fruits"),
                      _buildCategoryChip(
                          "Pulses", _selectedCategory == "Pulses"),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Top Listings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Top Listings",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "View All",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Dynamic Listing Cards
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('listings')
                      .where('userId', isEqualTo: _auth.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text("Error loading listings"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No listings found"));
                    }

                    final listings = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title =
                          data['title']?.toString().toLowerCase() ?? '';
                      final categoryMatch = _selectedCategory == "All" ||
                          data['category'] == _selectedCategory;
                      return title
                              .contains(_searchController.text.toLowerCase()) &&
                          categoryMatch;
                    }).toList();

                    return Column(
                      children: listings.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isPositive =
                            data['change']?.toString().contains("+") ?? true;
                        return Column(
                          children: [
                            _buildListingCard(
                              data['title'] ?? "Unknown",
                              data['description'] ?? "No description",
                              data['price'] ?? "N/A",
                              data['change'] ?? "+0.0%",
                              data['quantity'] ?? "N/A",
                              isPositive,
                              doc.id,
                              data['imageUrl'],
                            ),
                            const SizedBox(height: 15),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 25),

                // Market Trends (Static for now)
                const Text(
                  "Market Trends",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTrendItem("Rice", "₹45", "+2.3%"),
                      const Divider(),
                      _buildTrendItem("Wheat", "₹32", "-1.5%"),
                      const Divider(),
                      _buildTrendItem("Corn", "₹28", "+2.8%"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showListingForm(),
        backgroundColor: Colors.green,
        label: const Text("List Your Crop"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMarketStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        selectedColor: Colors.green,
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = selected ? label : null;
          });
        },
      ),
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
              location:
                  'Texas', // Replace with actual location from data if available
              phoneNumber:
                  '123-456-7890', // Replace with actual phone from data if available
              category:
                  'Grains', // Replace with actual category from data if available
              isSold:
                  false, // Replace with actual isSold from data if available
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    )
                  : Icon(
                      Icons.grass,
                      size: 40,
                      color: Colors.green[400],
                    ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          change,
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String crop, String price, String change) {
    bool isPositive = change.contains("+");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            crop,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
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
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
