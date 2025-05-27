import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart'; // Using Get for navigation potentially
import 'package:shared_preferences/shared_preferences.dart';

// Define keys for SharedPreferences
const String wifiSsidKey = 'wifi_ssid';
const String wifiPasswordKey = 'wifi_password';

class WifiCredentialScreen extends StatefulWidget {
  const WifiCredentialScreen({Key? key}) : super(key: key);

  @override
  _WifiCredentialScreenState createState() => _WifiCredentialScreenState();
}

class _WifiCredentialScreenState extends State<WifiCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveCredentials() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String ssid = _ssidController.text.trim();
      final String password = _passwordController.text; // Don't trim password

      if (ssid.isEmpty) {
        Fluttertoast.showToast(msg: "SSID cannot be empty");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(wifiSsidKey, ssid);
        await prefs.setString(wifiPasswordKey, password);

        Fluttertoast.showToast(msg: "WiFi Credentials Saved!");

        // Navigate to the main app screen (replace with your actual initial screen logic)
        // Example: Assuming you have a screen like DeviceListScreen or similar
        // Or if BluetoothTest is the direct next step after potentially connecting
        // Get.offAll(() => BluetoothTest(chargerId: "SOME_ID")); // Needs appropriate chargerId handling
        // For now, just pop or use a placeholder
        Get.offAllNamed('/home'); // Navigate to home or device list screen
      } catch (e) {
        Fluttertoast.showToast(
            msg: "Error saving credentials: ${e.toString()}");
      } finally {
        // Ensure loading state is reset even on error, if screen is still mounted
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Factory WiFi Credentials"),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Please enter the WiFi credentials for the network the chargers will connect to during testing.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: _ssidController,
                  decoration: InputDecoration(
                    labelText: 'WiFi SSID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wifi),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the WiFi SSID';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'WiFi Password (leave empty if none)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  // No validator for password, can be empty
                ),
                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveCredentials,
                        style: ElevatedButton.styleFrom(
                          minimumSize:
                              Size(double.infinity, 50), // Full width, taller
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text('Save and Continue'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
