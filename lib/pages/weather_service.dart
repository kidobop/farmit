import 'dart:convert'; // For jsonDecode
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Mapping of Indian states to approximate latitude/longitude (representative cities)
  static const Map<String, Map<String, double>> _stateToCoordinates = {
    'Andaman and Nicobar': {'lat': 11.7401, 'lon': 92.6586}, // Port Blair
    'Andhra Pradesh': {'lat': 17.3606, 'lon': 78.4767}, // Hyderabad
    'Arunachal Pradesh': {'lat': 27.1020, 'lon': 93.6166}, // Itanagar
    'Assam': {'lat': 26.1445, 'lon': 91.7362}, // Guwahati
    'Bihar': {'lat': 25.5941, 'lon': 85.1376}, // Patna
    'Chandigarh': {'lat': 30.7333, 'lon': 76.7794}, // Chandigarh
    'Chattisgarh': {'lat': 21.2514, 'lon': 81.6296}, // Raipur
    'Goa': {'lat': 15.2993, 'lon': 74.1240}, // Panaji
    'Gujarat': {'lat': 23.0225, 'lon': 72.5714}, // Ahmedabad
    'Haryana': {'lat': 29.0588, 'lon': 76.0856}, // Chandigarh
    'Himachal Pradesh': {'lat': 31.1048, 'lon': 77.1734}, // Shimla
    'Jammu and Kashmir': {'lat': 34.0837, 'lon': 74.7974}, // Srinagar
    'Jharkhand': {'lat': 23.3441, 'lon': 85.3096}, // Ranchi
    'Karnataka': {'lat': 12.9716, 'lon': 77.5946}, // Bangalore
    'Kerala': {'lat': 8.5241, 'lon': 76.9366}, // Thiruvananthapuram
    'Madhya Pradesh': {'lat': 23.2599, 'lon': 77.4126}, // Bhopal
    'Maharashtra': {'lat': 19.0760, 'lon': 72.8777}, // Mumbai
    'Manipur': {'lat': 24.7991, 'lon': 93.9370}, // Imphal
    'Meghalaya': {'lat': 25.5788, 'lon': 91.8933}, // Shillong
    'Mizoram': {'lat': 23.7271, 'lon': 92.7176}, // Aizawl
    'NCT of Delhi': {'lat': 28.7041, 'lon': 77.1025}, // Delhi
    'Nagaland': {'lat': 25.6673, 'lon': 94.1053}, // Kohima
    'Odisha': {'lat': 20.9517, 'lon': 85.0985}, // Bhubaneswar
    'Pondicherry': {'lat': 11.9416, 'lon': 79.8083}, // Puducherry
    'Punjab': {'lat': 30.7333, 'lon': 76.7794}, // Chandigarh
    'Rajasthan': {'lat': 26.9124, 'lon': 75.7873}, // Jaipur
    'Sikkim': {'lat': 27.5330, 'lon': 88.5122}, // Gangtok
    'Tamil Nadu': {'lat': 13.0827, 'lon': 80.2707}, // Chennai
    'Telangana': {'lat': 17.3850, 'lon': 78.4867}, // Hyderabad
    'Tripura': {'lat': 23.9408, 'lon': 91.9882}, // Agartala
    'Uttar Pradesh': {'lat': 26.8467, 'lon': 80.9462}, // Lucknow
    'Uttrakhand': {'lat': 30.3165, 'lon': 78.0322}, // Dehradun
    'West Bengal': {'lat': 22.5726, 'lon': 88.3639}, // Kolkata
  };

  // Fetch weather data based on the user's state
  Future<Map<String, dynamic>> fetchWeather(String state) async {
    try {
      // Map the state to coordinates
      final coordinates =
          _stateToCoordinates[state] ?? _stateToCoordinates['NCT of Delhi']!;
      final lat = coordinates['lat']!;
      final lon = coordinates['lon']!;

      // Construct the API URL
      final url =
          '$_baseUrl?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m,weather_code&forecast_days=1&timezone=auto';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentWeather = data['current_weather'];
        //final hourlyWeather = data['hourly'];
        final weatherCode = currentWeather['weathercode'];
        final temperature = currentWeather['temperature'].toString();
        final weatherDescription = _getWeatherDescription(weatherCode);

        return {
          'temperature': temperature,
          'description': weatherDescription,
          'icon': _getWeatherIcon(weatherCode),
        };
      } else {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  // Convert Open-Meteo weather code to description
  String _getWeatherDescription(int weatherCode) {
    // Open-Meteo weather codes: https://open-meteo.com/en/docs
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Mainly clear';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 80:
      case 81:
      case 82:
        return 'Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  // Get Open-Meteo weather icon code
  String _getWeatherIcon(int weatherCode) {
    // Simplified icon mapping based on weather code
    switch (weatherCode) {
      case 0:
        return '01d'; // Clear sky (day)
      case 1:
      case 2:
      case 3:
        return '02d'; // Mainly clear (day)
      case 45:
      case 48:
        return '50d'; // Fog
      case 51:
      case 53:
      case 55:
        return '09d'; // Drizzle
      case 61:
      case 63:
      case 65:
        return '10d'; // Rain
      case 80:
      case 81:
      case 82:
        return '09d'; // Showers
      case 95:
      case 96:
      case 99:
        return '11d'; // Thunderstorm
      default:
        return '01d'; // Default to clear sky
    }
  }

  // Get the URL for the weather icon (using OpenWeatherMap icon style for consistency)
  static String getWeatherIconUrl(String iconCode) {
    return 'http://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}
