import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'tool_details_page.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedCategory = "All";

  // Form controllers for adding/editing tools
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _conditionController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _specificationsController = TextEditingController();
  String _category = "Tractors";
  String? _toolId;
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
    _phoneController.dispose();
    _conditionController.dispose();
    _availabilityController.dispose();
    _specificationsController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
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

  void _showToolForm({String? toolId}) async {
    if (toolId != null) {
      final doc = await _firestore.collection('tools').doc(toolId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _priceController.text = data['price'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _conditionController.text = data['condition'] ?? '';
        _availabilityController.text = data['availability'] ?? '';
        _specificationsController.text = data['specifications'] ?? '';
        _category = data['category'] ?? 'Tractors';
        _imageUrl = data['imageUrl'];
        _toolId = toolId;
        _selectedImage = null;
      }
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _phoneController.clear();
      _conditionController.clear();
      _availabilityController.clear();
      _specificationsController.clear();
      _category = "Tractors";
      _imageUrl = null;
      _toolId = null;
      _selectedImage = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_toolId == null ? "Add Tool" : "Edit Tool"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  decoration: const InputDecoration(
                      labelText: "Price (e.g., ₹2,500/day)"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a price" : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter a phone number" : null,
                ),
                TextFormField(
                  controller: _conditionController,
                  decoration: const InputDecoration(
                      labelText: "Condition (e.g., New, Used)"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter the condition" : null,
                ),
                TextFormField(
                  controller: _availabilityController,
                  decoration: const InputDecoration(
                      labelText: "Availability (e.g., Available, Rented)"),
                  validator: (value) => value!.isEmpty
                      ? "Please enter availability status"
                      : null,
                ),
                TextFormField(
                  controller: _specificationsController,
                  decoration: const InputDecoration(
                      labelText: "Specifications (e.g., 75 HP, 4WD)"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter specifications" : null,
                ),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: [
                    "Tractors",
                    "Harvesters",
                    "Sprayers",
                    "Seeders",
                    "Plows",
                    "Cultivators",
                    "Irrigation Systems",
                    "Other"
                  ]
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
                  if (newImageUrl == null) return;
                }

                final userId = _auth.currentUser!.uid;
                final data = {
                  'title': _titleController.text.trim(),
                  'description': _descriptionController.text.trim(),
                  'price': _priceController.text.trim(),
                  'phoneNumber': _phoneController.text.trim(),
                  'condition': _conditionController.text.trim(),
                  'availability': _availabilityController.text.trim(),
                  'specifications': _specificationsController.text.trim(),
                  'category': _category,
                  'userId': userId,
                  'createdAt': FieldValue.serverTimestamp(),
                  if (newImageUrl != null) 'imageUrl': newImageUrl,
                };

                try {
                  if (_toolId == null) {
                    await _firestore.collection('tools').add(data);
                  } else {
                    await _firestore
                        .collection('tools')
                        .doc(_toolId)
                        .update(data);
                  }
                  Navigator.pop(context);
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving tool: $e')),
                  );
                }
              }
            },
            child: Text(_toolId == null ? "Add" : "Save"),
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
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
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
                            hintText: "Search equipment...",
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                const Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(
                          "All", _selectedCategory == "All", Colors.grey),
                      _buildCategoryChip("Tractors",
                          _selectedCategory == "Tractors", Colors.green),
                      _buildCategoryChip("Harvesters",
                          _selectedCategory == "Harvesters", Colors.orange),
                      _buildCategoryChip("Sprayers",
                          _selectedCategory == "Sprayers", Colors.blue),
                      _buildCategoryChip("Seeders",
                          _selectedCategory == "Seeders", Colors.purple),
                      _buildCategoryChip(
                          "Plows", _selectedCategory == "Plows", Colors.brown),
                      _buildCategoryChip("Cultivators",
                          _selectedCategory == "Cultivators", Colors.teal),
                      _buildCategoryChip(
                          "Irrigation Systems",
                          _selectedCategory == "Irrigation Systems",
                          Colors.cyan),
                      _buildCategoryChip(
                          "Other", _selectedCategory == "Other", Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "All Equipment",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('tools').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading tools"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No tools found"));
                    }

                    final tools = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title =
                          data['title']?.toString().toLowerCase() ?? '';
                      final categoryMatch = _selectedCategory == "All" ||
                          data['category'] == _selectedCategory;
                      return title
                              .contains(_searchController.text.toLowerCase()) &&
                          categoryMatch;
                    }).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tools.length,
                      itemBuilder: (context, index) {
                        final doc = tools[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return Column(
                          children: [
                            _buildEquipmentCard(
                              data['title'] ?? "Unknown",
                              data['description'] ?? "No description",
                              data['price'] ?? "N/A",
                              data['imageUrl'],
                              doc.id,
                              data,
                            ),
                            const SizedBox(height: 15),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showToolForm(),
        backgroundColor: Colors.green,
        label: const Text("Add Equipment"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        selectedColor: color,
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = selected ? label : "All";
          });
        },
      ),
    );
  }

  Widget _buildEquipmentCard(
    String title,
    String description,
    String price,
    String? imageUrl,
    String toolId,
    Map<String, dynamic> data,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToolDetailsPage(
              title: title,
              description: description,
              price: price,
              category: data['category'] ?? 'N/A',
              imageUrl: imageUrl,
              toolId: toolId,
              userId: data['userId'] ?? '',
              phoneNumber: data['phoneNumber'] ?? 'N/A',
              onEdit: () => _showToolForm(toolId: toolId),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(
                          Icons.agriculture,
                          size: 40,
                          color: Colors.grey),
                    )
                  : const Icon(
                      Icons.agriculture,
                      size: 40,
                      color: Colors.grey,
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
                    ],
                  ),
                  const SizedBox(height: 8),
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
                        '₹$price',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Rent Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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
}
