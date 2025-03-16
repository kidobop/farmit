import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shimmer/shimmer.dart'; // Add shimmer package for loading effect

// Assuming sensor_analysis.dart is available
import 'sensor_analysis.dart';

class SensorDataPage extends StatefulWidget {
  const SensorDataPage({super.key});

  @override
  State<SensorDataPage> createState() => _SensorDataPageState();
}

class _SensorDataPageState extends State<SensorDataPage>
    with SingleTickerProviderStateMixin {
  final FirebaseDatabase _database = FirebaseDatabase.instance
    ..setPersistenceEnabled(true);
  late DatabaseReference _databaseRef;
  Map<String, dynamic>? _sensorData;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _database.databaseURL = 'https://farmit-e496d-default-rtdb.firebaseio.com/';
    _databaseRef = _database.ref('sensorData');
    _fetchSensorData();

    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSensorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _databaseRef.get();
      if (snapshot.exists) {
        final rawData = snapshot.value;
        if (rawData is Map) {
          final typedData =
              rawData.map((key, value) => MapEntry(key.toString(), value));
          setState(() {
            _sensorData = typedData.cast<String, dynamic>();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Invalid data format: Expected a Map";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "No sensor data found";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching data: $e";
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}";
  }

  MapEntry<String, String>? _getLatestReading(Map<String, dynamic> readings) {
    if (readings.isEmpty) return null;
    final sortedKeys = readings.keys.toList()
      ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    final latestKey = sortedKeys.first;
    return MapEntry(latestKey, readings[latestKey].toString());
  }

  Map<String, double> _getMinMax(Map<String, dynamic> readings) {
    final values = readings.values
        .map((value) => double.tryParse(value.toString()))
        .where((value) => value != null && !value.isNaN)
        .cast<double>()
        .toList();
    if (values.isEmpty) {
      return {'min': 0.0, 'max': 0.0};
    }
    return {
      'min': values.reduce((a, b) => a < b ? a : b),
      'max': values.reduce((a, b) => a > b ? a : b),
    };
  }

  String _toCamelCase(String title) {
    final words = title.split(' ');
    if (words.isEmpty) return '';
    return words
        .asMap()
        .map((index, word) => MapEntry(
              index,
              index == 0
                  ? word.toLowerCase()
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
            ))
        .values
        .join('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Softer background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sensor Insights",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green, size: 28),
            onPressed: _fetchSensorData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerEffect()
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _sensorData == null
                  ? const Center(
                      child: Text(
                        "No data available",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSensorCard(
                                title: "Air Humidity",
                                unit: "%",
                                data: (_sensorData!['airHumidity'] as Map?)
                                        ?.cast<String, dynamic>() ??
                                    {},
                                icon: Icons.water_drop,
                                gradientColors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade800
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildSensorCard(
                                title: "Air Temperature",
                                unit: "°C",
                                data: (_sensorData!['airTemperature'] as Map?)
                                        ?.cast<String, dynamic>() ??
                                    {},
                                icon: Icons.thermostat,
                                gradientColors: [
                                  Colors.orange.shade400,
                                  Colors.orange.shade800
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildSensorCard(
                                title: "Soil Moisture",
                                unit: "%",
                                data: (_sensorData!['soilMoisture'] as Map?)
                                        ?.cast<String, dynamic>() ??
                                    {},
                                icon: Icons.opacity,
                                gradientColors: [
                                  Colors.green.shade400,
                                  Colors.green.shade800
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildSensorCard(
                                title: "Soil pH",
                                unit: "",
                                data: (_sensorData!['soilPH'] as Map?)
                                        ?.cast<String, dynamic>() ??
                                    {},
                                icon: Icons.science,
                                gradientColors: [
                                  Colors.purple.shade400,
                                  Colors.purple.shade800
                                ],
                                handleNaN: true,
                              ),
                              const SizedBox(height: 20),
                              _buildSensorCard(
                                title: "Soil Salinity",
                                unit: "",
                                data: (_sensorData!['soilSalinity'] as Map?)
                                        ?.cast<String, dynamic>() ??
                                    {},
                                icon: Icons.scatter_plot,
                                gradientColors: [
                                  Colors.brown.shade400,
                                  Colors.brown.shade800
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: 5, // Simulate 5 cards
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String unit,
    required Map<String, dynamic> data,
    required IconData icon,
    required List<Color> gradientColors,
    bool handleNaN = false,
  }) {
    final latestReading = _getLatestReading(data);
    final minMax = _getMinMax(data);
    final sensorKey = _toCamelCase(title);
    final analysis = SensorAnalysis.analyzeSensor(sensorKey, data);

    return GestureDetector(
      onTap: () {
        // Add detailed view or trend analysis navigation here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tapped on $title - Implement detailed view")),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 18),
              ],
            ),
            const SizedBox(height: 15),
            latestReading == null
                ? const Text(
                    "No data available",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            handleNaN && latestReading.value == "NaN"
                                ? "Not Available"
                                : "${latestReading.value} $unit",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: handleNaN && latestReading.value == "NaN"
                                  ? Colors.white70
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            _formatTimestamp(latestReading.key),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Min: ${minMax['min']?.toStringAsFixed(2) ?? 'N/A'} $unit",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            "Max: ${minMax['max']?.toStringAsFixed(2) ?? 'N/A'} $unit",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: analysis.contains("Good")
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          analysis,
                          style: TextStyle(
                            fontSize: 14,
                            color: analysis.contains("Good")
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
