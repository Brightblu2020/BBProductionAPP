import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://my.brightblu.com/api';
  String? _authToken;
  String? _userId;

  // Getters for auth data
  String? get authToken => _authToken;
  String? get userId => _userId;

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('API Service: Attempting login for email: $email');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('API Service: Login response status code: ${response.statusCode}');
      print('API Service: Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        _userId = data['user']['_id'];
        print('API Service: Login successful. Token and userId stored');
        return data;
      } else {
        print('API Service: Login failed with status ${response.statusCode}');
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      print('API Service: Error during login: $e');
      throw Exception('Error during login: $e');
    }
  }

  Future<List<String>> getGroupNames() async {
    print('API Service: Fetching group names for userId: $_userId');
    if (_userId == null) {
      print('API Service: Error - User not logged in');
      throw Exception('User not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/group/$_userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      print(
        'API Service: Get groups response status code: ${response.statusCode}',
      );
      print('API Service: Get groups response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> groups = jsonDecode(response.body);
        final groupNames =
            groups.map((group) => group['groupName'] as String).toList();
        print('API Service: Successfully fetched ${groupNames.length} groups');
        return groupNames;
      } else {
        print(
          'API Service: Failed to fetch groups with status ${response.statusCode}',
        );
        throw Exception('Failed to fetch groups: ${response.body}');
      }
    } catch (e) {
      print('API Service: Error fetching groups: $e');
      throw Exception('Error fetching groups: $e');
    }
  }

  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String groupName,
  }) async {
    print('API Service: Registering device: $deviceId with group: $groupName');
    if (_userId == null) {
      print('API Service: Error - User not logged in');
      throw Exception('User not logged in');
    }

    try {
      // Create form data
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/charger/create/$_userId'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_authToken';

      // Add form fields
      request.fields['chargerId'] = deviceId;
      request.fields['chargePointModel'] = 'Type 2:Single Output AC';
      request.fields['numberOfPorts'] = '1';
      request.fields['groupName'] = groupName;
      request.fields['isPublic'] = 'false';
      request.fields['chargerLatitude'] = '';
      request.fields['chargerLongitude'] = '';
      request.fields['chargerAddress'] = '';

      print('API Service: Registration request form data: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        'API Service: Register device response status code: ${response.statusCode}',
      );
      print('API Service: Register device response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('API Service: Device registration successful');
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] == 'Charger Already Exists') {
          print('API Service: Device already exists - treating as success');
          return {'message': 'Device already registered'};
        }
        print(
          'API Service: Device registration failed with status ${response.statusCode}',
        );
        throw Exception('Failed to register device: ${response.body}');
      }
    } catch (e) {
      print('API Service: Error registering device: $e');
      throw Exception('Error registering device: $e');
    }
  }

  Future<Map<String, dynamic>> startRemoteTransaction(String deviceId) async {
    print('API Service: Starting remote transaction for device: $deviceId');
    if (_userId == null) {
      print('API Service: Error - User not logged in');
      throw Exception('User not logged in');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ocpp/remotestarttransaction'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'cpid': deviceId,
          'connectorId': 1,
          'userId': _userId,
        }),
      );

      print(
        'API Service: Start transaction response status code: ${response.statusCode}',
      );
      print('API Service: Start transaction response body: ${response.body}');

      if (response.statusCode == 200) {
        print('API Service: Remote transaction start successful');
        return jsonDecode(response.body);
      } else {
        print(
          'API Service: Remote transaction start failed with status ${response.statusCode}',
        );
        throw Exception('Failed to start remote transaction: ${response.body}');
      }
    } catch (e) {
      print('API Service: Error starting remote transaction: $e');
      throw Exception('Error starting remote transaction: $e');
    }
  }

  Future<Map<String, dynamic>> stopRemoteTransaction(String deviceId) async {
    try {
      print('API Service: Stopping remote transaction for device: $deviceId');
      final response = await http.post(
        Uri.parse('https://my.brightblu.com/api/ocpp/remotestoptransaction'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'cpid': deviceId,
          'connectorId': 1,
          'userId': _userId,
        }),
      );

      print(
        'API Service: Stop transaction response status code: ${response.statusCode}',
      );
      print('API Service: Stop transaction response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message'] == 'Sent Message to Charger') {
          print('API Service: Remote transaction stop successful');
          return responseData;
        } else {
          print('API Service: Remote transaction stop failed');
          return {'error': 'Failed to stop charging session'};
        }
      } else {
        print(
          'API Service: Remote transaction stop failed with status code: ${response.statusCode}',
        );
        return {
          'error': 'Failed to stop charging session: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('API Service: Error stopping remote transaction: $e');
      return {'error': 'Error stopping charging session: $e'};
    }
  }
}
