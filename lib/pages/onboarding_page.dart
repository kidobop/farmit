import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingPage extends StatefulWidget {
  final String uid;
  const OnboardingPage({super.key, required this.uid});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _role = 'Farmer'; // Default role
  bool _isLoading = false;

  Future<void> _submitOnboarding() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Store user data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .set({
          'name': _nameController.text.trim(),
          'location': _locationController.text.trim(),
          'role': _role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save data: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tell us about yourself",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter your name" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                      labelText: "Location (e.g., City, State)"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter your location" : null,
                ),
                const SizedBox(height: 20),
                const Text("Are you a:", style: TextStyle(fontSize: 16)),
                RadioListTile<String>(
                  title: const Text("Farmer"),
                  value: "Farmer",
                  groupValue: _role,
                  onChanged: (value) {
                    setState(() {
                      _role = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text("Buyer"),
                  value: "Buyer",
                  groupValue: _role,
                  onChanged: (value) {
                    setState(() {
                      _role = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitOnboarding,
                        child: const Text("Continue"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
