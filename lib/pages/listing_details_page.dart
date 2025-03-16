import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // For sharing

class ListingDetailsPage extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String quantity;
  final String location;
  final String phoneNumber;
  final String category;
  final bool isSold;
  final String? imageUrl;
  final String listingId;
  final String userId;
  final VoidCallback onEdit; // New callback for edit action

  const ListingDetailsPage({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.quantity,
    required this.location,
    required this.phoneNumber,
    required this.category,
    required this.isSold,
    this.imageUrl,
    required this.listingId,
    required this.userId,
    required this.onEdit, // Require the callback
  });

  void _launchPhone(BuildContext context) async {
    final url = 'tel:$phoneNumber';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching phone dialer: $e')),
      );
    }
  }

  // Delete the listing with confirmation
  Future<void> _deleteListing(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('listings')
            .doc(listingId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted successfully')),
        );
        Navigator.pop(context); // Return to previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting listing: $e')),
        );
      }
    }
  }

  // Share the listing
  void _shareListing() {
    final shareText =
        'Check out this listing on FarmIt: $title\nPrice: $price\nQuantity: $quantity\nLocation: $location\nContact: $phoneNumber';
    Share.share(shareText, subject: 'FarmIt Listing: $title');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser != null && currentUser.uid == userId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.grass,
                          size: 100,
                          color: Colors.green,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.grass,
                        size: 100,
                        color: Colors.green,
                      ),
                    ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit(); // Use the callback
                      Navigator.pop(context); // Return to MarketplacePage
                    } else if (value == 'delete') {
                      _deleteListing(context);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareListing,
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to favorites')),
                  );
                },
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  if (isSold)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SOLD',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Category chip
                  Chip(
                    backgroundColor: Colors.green[50],
                    label: Text(
                      category,
                      style: TextStyle(color: Colors.green[800]),
                    ),
                    avatar: Icon(
                      Icons.category,
                      color: Colors.green[800],
                      size: 16,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Details Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.production_quantity_limits,
                              'Quantity', quantity),
                          _buildDetailRow(
                              Icons.location_on, 'Location', location),
                          _buildDetailRow(
                            Icons.phone,
                            'Phone',
                            phoneNumber,
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: phoneNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Phone number copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () => _launchPhone(context),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    elevation: 0,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final smsUrl =
                        'sms:$phoneNumber?body=Hi, I am interested in your listing: $title';
                    try {
                      if (await canLaunchUrl(Uri.parse(smsUrl))) {
                        await launchUrl(Uri.parse(smsUrl));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not launch SMS app')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error launching SMS: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Message Seller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, color: Colors.green[700], size: 20),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: onTap != null ? Colors.blue : null,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.content_copy, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
