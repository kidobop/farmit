// sensor_analysis.dart
class SensorAnalysis {
  // Define acceptable ranges for each sensor (based on typical farming conditions)
  static const Map<String, Map<String, double>> acceptableRanges = {
    'airHumidity': {'min': 40.0, 'max': 70.0}, // % (ideal range for most crops)
    'airTemperature': {
      'min': 15.0,
      'max': 35.0
    }, // °C (general crop growth range)
    'soilMoisture': {
      'min': 20.0,
      'max': 60.0
    }, // % (varies by crop, general range)
    'soilPH': {
      'min': 1.0,
      'max': 7.5
    }, // (neutral to slightly acidic/alkaline for most crops)
    'soilSalinity': {
      'min': 0.0,
      'max': 4.0
    }, // dS/m (low salinity for healthy growth)
  };

  // Analyze the latest reading for a given sensor
  static String analyzeSensor(
      String sensorType, Map<String, dynamic> readings) {
    final latestReading = _getLatestReading(readings);
    if (latestReading == null) {
      return "No data available for analysis";
    }

    final value = double.tryParse(latestReading.value);
    if (value == null || value.isNaN) {
      return "Invalid reading for analysis";
    }

    final range = acceptableRanges[sensorType];
    if (range == null) {
      return "No acceptable range defined for $sensorType";
    }

    if (value >= range['min']! && value <= range['max']!) {
      return "Good: Value ($value) is within the acceptable range (${range['min']} - ${range['max']})";
    } else if (value < range['min']!) {
      return "Alert: Value ($value) is below the minimum acceptable range (${range['min']})";
    } else {
      return "Alert: Value ($value) is above the maximum acceptable range (${range['max']})";
    }
  }

  // Helper method to get the latest reading (same as in SensorDataPage)
  static MapEntry<String, String>? _getLatestReading(
      Map<String, dynamic> readings) {
    if (readings.isEmpty) return null;
    final sortedKeys = readings.keys.toList()
      ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    final latestKey = sortedKeys.first;
    return MapEntry(latestKey, readings[latestKey].toString());
  }
}
