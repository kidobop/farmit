import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MarketPricesPage extends StatefulWidget {
  const MarketPricesPage({super.key});

  @override
  State<MarketPricesPage> createState() => _MarketPricesPageState();
}

class _MarketPricesPageState extends State<MarketPricesPage> {
  String? _selectedState;
  String? _selectedCommodity;
  final TextEditingController _commodityController = TextEditingController();
  List<Map<String, String>> _marketData = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalRecords = 0;
  int _totalPages = 0;

  final List<String> _states = [
    'Andaman and Nicobar',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'NCT of Delhi',
    'Nagaland',
    'Odisha',
    'Pondicherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttrakhand',
    'West Bengal',
  ];

  late final String _apiKey;

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['MANDI_API'] ?? 'DEFAULT_API_KEY';
    if (_apiKey == 'DEFAULT_API_KEY') {
      setState(() {
        _errorMessage = 'API key not found in .env file';
      });
    }
  }

  @override
  void dispose() {
    _commodityController.dispose();
    super.dispose();
  }

  // Helper function to convert a string to proper case
  String _toProperCase(String input) {
    if (input.isEmpty) return input;
    return input
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : word)
        .join(' ');
  }

  Future<void> _fetchMarketData(String state,
      {String? commodity, int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _marketData = [];
      _currentPage = page;
    });

    try {
      final offset = (_currentPage - 1) * _itemsPerPage;
      String url =
          'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?api-key=$_apiKey&format=xml&filters[state.keyword]=$state&limit=$_itemsPerPage&offset=$offset';
      if (commodity != null && commodity.isNotEmpty) {
        url += '&filters[commodity.keyword]=$commodity';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);

        final total = int.parse(document.findAllElements('total').first.text);
        setState(() {
          _totalRecords = total;
          _totalPages = (total / _itemsPerPage).ceil();
        });

        final records = document
            .findAllElements('item')
            .where((element) => element.parentElement?.name.local == 'records');

        final List<Map<String, String>> data = records.map((record) {
          return {
            'state': record.findElements('state').first.text,
            'district': record.findElements('district').first.text,
            'market': record.findElements('market').first.text,
            'commodity': record.findElements('commodity').first.text,
            'variety': record.findElements('variety').first.text,
            'grade': record.findElements('grade').first.text,
            'arrival_date': record.findElements('arrival_date').first.text,
            'min_price': record.findElements('min_price').first.text,
            'max_price': record.findElements('max_price').first.text,
            'modal_price': record.findElements('modal_price').first.text,
          };
        }).toList();

        setState(() {
          _marketData = data;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _fetchMarketData(_selectedState!,
          commodity: _selectedCommodity, page: _currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _fetchMarketData(_selectedState!,
          commodity: _selectedCommodity, page: _currentPage - 1);
    }
  }

  void _searchMarketData() {
    if (_selectedState != null && _selectedState!.isNotEmpty) {
      final formattedCommodity =
          _toProperCase(_commodityController.text.trim());
      setState(() {
        _selectedCommodity = formattedCommodity;
        _commodityController.text = formattedCommodity; // Update the text field
        _currentPage = 1; // Reset to first page on search
        _totalRecords = 0;
        _totalPages = 0;
      });
      _fetchMarketData(_selectedState!, commodity: _selectedCommodity, page: 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a state first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 62, 148, 36),
              Colors.teal.shade300
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Market Prices',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // State Dropdown with modern styling
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select State',
                              border: InputBorder.none,
                            ),
                            value: _selectedState,
                            items: _states.map((state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(state),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedState = value;
                                _currentPage =
                                    1; // Reset to first page on state change
                                _totalRecords = 0;
                                _totalPages = 0;
                              });
                              if (value != null) {
                                _fetchMarketData(value, page: 1);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Commodity Input with modern styling
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _commodityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter Commodity (e.g., Banana)',
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    final formattedValue = _toProperCase(value);
                                    _commodityController.value =
                                        TextEditingValue(
                                      text: formattedValue,
                                      selection: TextSelection.collapsed(
                                          offset: formattedValue.length),
                                    );
                                    setState(() {
                                      _selectedCommodity = formattedValue;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search,
                                    color: Colors.teal),
                                onPressed: _searchMarketData,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Content Area
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildContent(),
                          ),
                        ),
                        // Pagination Controls
                        if (_marketData.isNotEmpty && _totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed:
                                      _currentPage > 1 ? _previousPage : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Previous',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Text(
                                  'Page $_currentPage of $_totalPages',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _currentPage < _totalPages
                                      ? _nextPage
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Next',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red.shade700, fontSize: 16),
        ),
      );
    } else if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
      );
    } else if (_selectedState == null) {
      return const Center(
        child: Text(
          'Please select a state to view market prices.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    } else if (_marketData.isEmpty) {
      return const Center(
        child: Text(
          'No market data available for this state and commodity.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _marketData.length,
        itemBuilder: (context, index) {
          final data = _marketData[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                data['commodity']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Market: ${data['market']}', style: _subtitleStyle),
                  Text('Variety: ${data['variety']}', style: _subtitleStyle),
                  Text('Modal Price: ₹${data['modal_price']}/Quintal',
                      style: _priceStyle),
                  Text('Min Price: ₹${data['min_price']}/Quintal',
                      style: _subtitleStyle),
                  Text('Max Price: ₹${data['max_price']}/Quintal',
                      style: _subtitleStyle),
                  Text('Date: ${data['arrival_date']}', style: _subtitleStyle),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  final TextStyle _subtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey.shade700,
  );

  final TextStyle _priceStyle = TextStyle(
    fontSize: 14,
    color: Colors.teal.shade700,
    fontWeight: FontWeight.w600,
  );
}
