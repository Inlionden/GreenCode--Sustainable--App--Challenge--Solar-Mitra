import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'apsl_sun_calc.dart'; // Assuming it's in the same directory

class SolarEstimatorScreen extends StatefulWidget {
  const SolarEstimatorScreen({super.key});

  @override
  State<SolarEstimatorScreen> createState() => _SolarEstimatorScreenState();
}

class _SolarEstimatorScreenState extends State<SolarEstimatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latitudeController = TextEditingController(text: "34.0522"); // Example: Los Angeles
  final _longitudeController = TextEditingController(text: "-118.2437"); // Example: Los Angeles
  final _panelCapacityController = TextEditingController(text: "5"); // kW
  final _peakSunHoursController = TextEditingController(text: "4.5"); // Average daily peak sun hours
  final _systemEfficiencyController = TextEditingController(text: "80"); // Percentage

  double? _estimatedDailyProduction;
  double? _estimatedMonthlyProduction;
  double? _estimatedYearlyProduction;
  String? _daylightHoursInfo;
  bool _isLoading = false;

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _panelCapacityController.dispose();
    _peakSunHoursController.dispose();
    _systemEfficiencyController.dispose();
    super.dispose();
  }

  Future<void> _calculateEstimate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _estimatedDailyProduction = null;
        _estimatedMonthlyProduction = null;
        _estimatedYearlyProduction = null;
        _daylightHoursInfo = null;
      });

      final lat = double.tryParse(_latitudeController.text);
      final lng = double.tryParse(_longitudeController.text);
      final capacity = double.tryParse(_panelCapacityController.text);
      final peakSunHours = double.tryParse(_peakSunHoursController.text);
      final efficiency = double.tryParse(_systemEfficiencyController.text);

      if (lat == null || lng == null || capacity == null || peakSunHours == null || efficiency == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid input. Please check values.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Basic estimation formula:
      // Daily Energy (kWh) = Panel Capacity (kW) * Peak Sun Hours * (System Efficiency / 100)
      final dailyKWh = capacity * peakSunHours * (efficiency / 100.0);

      // Get daylight hours for today as supplemental info
      try {
        final now = DateTime.now();
        final sunTimes = await SunCalc.getTimes(now, lat, lng);
        final sunrise = sunTimes['sunrise'];
        final sunset = sunTimes['sunset'];

        if (sunrise != null && sunset != null) {
          final duration = sunset.difference(sunrise);
          _daylightHoursInfo = "Approx. daylight today: ${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
        } else {
          _daylightHoursInfo = "Could not calculate daylight hours for the location.";
        }
      } catch (e) {
        _daylightHoursInfo = "Error fetching sun times: $e";
      }
      
      setState(() {
        _estimatedDailyProduction = dailyKWh;
        _estimatedMonthlyProduction = dailyKWh * 30; // Approximate
        _estimatedYearlyProduction = dailyKWh * 365; // Approximate
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Energy Estimator'),
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
              _buildTextField(
                controller: _panelCapacityController,
                label: 'Panel System Capacity (kW)',
                icon: Icons.solar_power,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              _buildTextField(
                controller: _peakSunHoursController,
                label: 'Avg. Daily Peak Sun Hours',
                icon: Icons.wb_sunny,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'Varies by location & season. Check local data.'
              ),
              _buildTextField(
                controller: _systemEfficiencyController,
                label: 'System Efficiency (%)',
                icon: Icons.flash_on,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: 'Typically 75-85%'
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.calculate),
                label: Text(_isLoading ? 'Calculating...' : 'Estimate Production'),
                onPressed: _isLoading ? null : _calculateEstimate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              if (_estimatedDailyProduction != null) ...[
                _buildResultCard(),
              ],
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
    List<TextInputFormatter>? inputFormatters,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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
            Text('Estimated Solar Production:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (_daylightHoursInfo != null) ...[
              Text(_daylightHoursInfo!, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              const Divider(height: 20),
            ],
            _buildResultRow('Daily:', '${_estimatedDailyProduction?.toStringAsFixed(2)} kWh'),
            _buildResultRow('Monthly (approx.):', '${_estimatedMonthlyProduction?.toStringAsFixed(2)} kWh'),
            _buildResultRow('Yearly (approx.):', '${_estimatedYearlyProduction?.toStringAsFixed(2)} kWh'),
            const SizedBox(height: 10),
            const Text(
              'Note: This is a simplified estimation. Actual production varies based on weather, shading, panel degradation, precise orientation, and other factors.',
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}