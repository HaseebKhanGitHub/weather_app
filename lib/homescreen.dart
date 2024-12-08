import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  static const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 10,
  );

  static const apiKey = '9f24f45f1a43cd906106cb78433a7be0';

  double? latitude;
  double? longitude;
  String cityName = '';
  double temperature = 0.0;
  String weatherDescription = '';

  // Icons icons;
  double mintemp = 0.0;
  double maxtemp = 0.0;
  int humidity = 0;
  double windSpeed = 0.0;
  int sunRise = 0;
  int sunSet = 0;
  String formattedSunrise = '';
  String formattedSunset = '';
  String iconCode = '';
  double feelLike = 0.0;

  @override
  void initState() {
    super.initState();
    getLocationAndFetchWeather();
  }

  Future<void> getLocationAndFetchWeather() async {
    await getLocation();
    if (latitude != null && longitude != null) {
      await getData(latitude!, longitude!);
    }
  }

  Future<void> getLocation() async {
    PermissionStatus permission = await Permission.location.request();

    if (permission == PermissionStatus.granted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            locationSettings: locationSettings);

        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });

        print("User's location: $latitude, $longitude");
      } catch (e) {
        print("Error fetching the location: $e");
      }
    } else if (permission == PermissionStatus.denied) {
      print("Location permission denied");
    } else if (permission == PermissionStatus.permanentlyDenied) {
      print('Location permission permanently denied');
      openAppSettings();
    }
  }

  Future<void> getData(double lat, double lon) async {
    // Reverse geocoding to fetch city name
    final reverseGeoResponse = await http.get(Uri.parse(
        'http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&appid=$apiKey'));

    if (reverseGeoResponse.statusCode == 200) {
      var reverseGeoData = json.decode(reverseGeoResponse.body);
      if (reverseGeoData.isNotEmpty) {
        setState(() {
          cityName = reverseGeoData[0]['name'];
        });
      }
    } else {
      print('Reverse geocoding failed: ${reverseGeoResponse.body}');
    }

    // Weather data
    final weatherResponse = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey'));

    try {
      if (weatherResponse.statusCode == 200) {
        var weatherData = json.decode(weatherResponse.body);

        setState(() {
          temperature = weatherData['main']['temp'];
          weatherDescription = weatherData['weather'][0]['description'];
          mintemp = weatherData['main']['temp_min'];
          maxtemp = weatherData['main']['temp_max'];
          windSpeed = weatherData['wind']['speed'];
          sunRise = weatherData['sys']['sunrise'];
          sunSet = weatherData['sys']['sunset'];
          iconCode = weatherData['weather'][0]['icon'];
          humidity = weatherData['main']['humidity'];
          feelLike = weatherData['main']['feels_like'];

          // Convert to readable format
          formattedSunrise = formatUnixTime(sunRise);
          formattedSunset = formatUnixTime(sunSet);
        });

        // print('Temperature: $temperature°C');
        // print('Weather Description: $weatherDescription');
        // print('new: $mintemp / $maxtemp');
        // print("windSpeed: $windSpeed");
        // print("Sun: $formattedSunrise , $formattedSunset");
      } else {
        print('Failed to load weather data: ${weatherResponse.body}');
      }
    } catch (e) {
      print('Error occurred while fetching weather data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 5,
        shadowColor: Colors.white,
        title: const Text(
          'Weather App',
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  cityName.isNotEmpty ? cityName : 'Fetching City...',
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      temperature != 0.0 ? '$temperature°C' : '...',
                      style: const TextStyle(
                          fontSize: 45,
                          color: Colors.white,
                          fontWeight: FontWeight.w400),
                    ),
                    SizedBox(width: 20),
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              mintemp != 0.0 ? '$mintemp°/' : '...',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                            Text(
                              maxtemp != 0.0 ? '$maxtemp°' : '...',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                        Text(
                          weatherDescription.isNotEmpty
                              ? weatherDescription
                              : '...',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(width: 10,),
                    if (iconCode.isNotEmpty)
                      Image.network(
                        'http://openweathermap.org/img/wn/$iconCode@2x.png',
                        width: 80,
                        height: 80,
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/feel_like.svg',
                            width: 50,
                            height: 50,
                          ),
                          Text(
                            "Feels Like",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                          Text(
                            feelLike != 0.0 ? '$feelLike°C' : '...',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 50,
                            color: Colors.blue,
                          ),
                          Text(
                            "Humidity",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                          Text(
                            humidity != 0 ? '$humidity%' : '...',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wind_power,
                            size: 50,
                            color: Colors.white,
                          ),
                          Text(
                            "Wind Speed",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                          Text(
                            windSpeed != 0.0 ? '$windSpeed km/h' : '...',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/sunrise.svg',
                                width: 50,
                                height: 50,
                              ),
                              Text(
                                "Sunrise",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                              Text(
                                sunRise != 0.0
                                    ? ' $formattedSunrise '
                                    : '...',
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.grey),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/sunset.svg',
                                width: 50,
                                height: 50,
                              ),
                              Text(
                                "Sunset",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                              Text(
                                sunSet != 0.0 ? ' $formattedSunset ' : '...',
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.grey),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await getLocationAndFetchWeather();
                  },
                  child: const Text(
                    'Refresh',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatUnixTime(int unixTime) {
  // Convert Unix timestamp to DateTime
  final dateTime =
  DateTime.fromMillisecondsSinceEpoch(unixTime * 1000, isUtc: true);

  // Format DateTime to a readable string (e.g., "6:30 AM")
  return DateFormat('h:mm a').format(dateTime.toLocal());
}
