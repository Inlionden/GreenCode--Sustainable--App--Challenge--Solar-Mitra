import 'package:flutter/material.dart';
import 'apsl_sun_calc.dart'; // Assuming it's in the same directory
import 'package:intl/intl.dart'; // For date formatting

class PanelAngleCalculatorScreen extends StatefulWidget {
  const PanelAngleCalculatorScreen({super.key});

  @override
  State<PanelAngleCalculatorScreen> createState() => _PanelAngleCalculatorScreenState();
}

class _PanelAngleCalculatorScreenState extends State<PanelAngleCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latitudeController = TextEditingController(text: "34.0522"); // Example: Los Angeles
  final _longitudeController = TextEditingController(text: "-118.2437"); // Example: Los Angeles
  
  DateTime _selectedDate = DateTime.now();
  double? _optimalTiltForDate;
  double? _yearRoundFixedTilt;
  double? _summerTilt;
  double? _winterTilt;
  String? _solarNoonTime;
  String? _sunAltitudeAtNoon;
  bool _isLoading = false;

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Clear previous results when date changes
        _optimalTiltForDate = null;
        _solarNoonTime = null;
        _sunAltitudeAtNoon = null;
      });
    }
  }

  Future<void> _calculateAngle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _optimalTiltForDate = null;
        _yearRoundFixedTilt = null;
        _summerTilt = null;
        _winterTilt = null;
        _solarNoonTime = null;
        _sunAltitudeAtNoon = null;
      });

      final lat = double.tryParse(_latitudeController.text);
      final lng = double.tryParse(_longitudeController.text);

      if (lat == null || lng == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid input. Please check values.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      try {
        // 1. Get solar noon for the selected date and location
        final sunTimes = await SunCalc.getTimes(_selectedDate, lat, lng);
        final solarNoon = sunTimes['solarNoon'];

        if (solarNoon == null) {
          throw Exception('Could not calculate solar noon.');
        }
        _solarNoonTime = DateFormat('HH:mm:ss').format(solarNoon.toLocal());

        // 2. Get sun position (altitude) at solar noon
        final sunPositionAtNoon = SunCalc.getPosition(solarNoon, lat, lng);
        final altitudeAtNoonRad = sunPositionAtNoon['altitude']; // in radians

        if (altitudeAtNoonRad == null) {
          throw Exception('Could not calculate sun altitude at noon.');
        }
        final altitudeAtNoonDeg = altitudeAtNoonRad * 180 / 3.1415926535; // Convert to degrees
        _sunAltitudeAtNoon = "${altitudeAtNoonDeg.toStringAsFixed(2)}°";

        // 3. Calculate optimal tilt for the date (panel perpendicular to sun at noon)
        // Tilt is often 90 - sun's altitude.
        // However, for practical purposes, tilt angle is usually from horizontal.
        // If sun is at 60 deg altitude, panel tilt is 90 - 60 = 30 deg from horizontal.
        // If latitude is positive (Northern Hemisphere), panel faces South.
        // If latitude is negative (Southern Hemisphere), panel faces North.
        // This calculation primarily gives the tilt magnitude.
        _optimalTiltForDate = (90 - altitudeAtNoonDeg).abs();
        if (altitudeAtNoonDeg < 0) { // Sun below horizon at noon (polar night)
          _optimalTiltForDate = 90; // Flat or very steep, effectively 90 for no direct sun
           _sunAltitudeAtNoon = "${altitudeAtNoonDeg.toStringAsFixed(2)}° (Sun below horizon)";
        }


        // 4. General rule-of-thumb tilts
        _yearRoundFixedTilt = lat.abs(); // General: tilt = latitude
        _summerTilt = (lat.abs() - 15).clamp(0, 90); // Summer: latitude - 15 degrees
        _winterTilt = (lat.abs() + 15).clamp(0, 90); // Winter: latitude + 15 degrees


      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Angle Calculator'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextField(
                controller: _latitudeController,
                label: 'Latitude (e.g., 34.0522)',
                icon: Icons.location_on,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
              _buildTextField(
                controller: _longitudeController,
                label: 'Longitude (e.g., -118.2437)',
                icon: Icons.location_on,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Selected Date: ${DateFormat.yMMMd().format(_selectedDate)}",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Change Date'),
                    onPressed: () => _pickDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.wb_sunny_outlined),
                label: Text(_isLoading ? 'Calculating...' : 'Calculate Optimal Angles'),
                onPressed: _isLoading ? null : _calculateAngle,
                 style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              if (_optimalTiltForDate != null || _yearRoundFixedTilt != null) ...[
                _buildResultCard(),
              ]
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calculated Panel Tilt Angles (from horizontal):', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (_solarNoonTime != null)
              Text('Solar Noon on ${DateFormat.yMMMd().format(_selectedDate)}: $_solarNoonTime (Local Time)', style: const TextStyle(fontStyle: FontStyle.italic)),
            if (_sunAltitudeAtNoon != null)
              Text('Sun Altitude at Solar Noon: $_sunAltitudeAtNoon', style: const TextStyle(fontStyle: FontStyle.italic)),

            if (_optimalTiltForDate != null) ...[
              const Divider(height: 20),
              _buildResultRow(
                'Optimal for ${DateFormat.yMMMd().format(_selectedDate)} (at Solar Noon):',
                '${_optimalTiltForDate!.toStringAsFixed(1)}°'
              ),
            ],
            const Divider(height: 20),
            Text('General Rule-of-Thumb Tilts:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            if (_yearRoundFixedTilt != null)
              _buildResultRow('Year-round Fixed:', '${_yearRoundFixedTilt!.toStringAsFixed(1)}°'),
            if (_summerTilt != null)
              _buildResultRow('Summer Optimized (approx.):', '${_summerTilt!.toStringAsFixed(1)}°'),
            if (_winterTilt != null)
              _buildResultRow('Winter Optimized (approx.):', '${_winterTilt!.toStringAsFixed(1)}°'),
            const SizedBox(height: 10),
            const Text(
              'Note: These are tilt angles from the horizontal. Panel azimuth (direction) is also crucial (typically South in Northern Hemisphere, North in Southern Hemisphere). Actual optimal angles can vary based on local conditions and specific energy needs throughout the year.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(value),
        ],
      ),
    );
  }
}