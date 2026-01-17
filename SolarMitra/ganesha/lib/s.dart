// simulator_model.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

// --- Enums ---
enum RoofType { flat, slanted, gabled, hip, custom }
enum PanelStatus { active, faulty, off, shaded, degraded, maintenance }
enum ObstacleType { chimney, ventPipe, skylight, dormer, treeShadow, acUnit, parapetWall }

// --- Classes ---
class Coordinate3D {
  final double x;
  final double y;
  final double z;

  const Coordinate3D(this.x, this.y, this.z);

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
  static Coordinate3D fromJson(Map<dynamic, dynamic> json) => Coordinate3D(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['z'] as num).toDouble(),
      );
  
  @override String toString() => 'Coord3D(x:$x, y:$y, z:$z)';
}

class RoofDimensions {
  final double length; // Typically along the ridge for gabled/hip
  final double width;  // Typically the span or depth
  final double baseHeight; // Eaves height
  final double pitch1; // Main roof pitch in degrees
  final double? pitch2; // Secondary pitch (e.g., for gabled ends or hip roof sections) in degrees
  final double orientation; // Azimuth of the primary roof face (0-360, N=0, E=90)

  const RoofDimensions({
    required this.length,
    required this.width,
    required this.baseHeight,
    required this.pitch1,
    this.pitch2,
    required this.orientation,
  });

  double get surfaceArea {
    // Simplified: This is highly dependent on RoofType and needs proper geometric calculation.
    // For a simple slanted roof (if pitch1 relates to the whole area):
    if (pitch1 > 0) {
      return (length * width) / math.cos(pitch1 * math.pi / 180);
    }
    return length * width; // Flat roof
  }

  Map<String, dynamic> toJson() => {
        'length': length, 'width': width, 'baseHeight': baseHeight,
        'pitch1': pitch1, 'pitch2': pitch2, 'orientation': orientation,
      };

  static RoofDimensions fromJson(Map<dynamic, dynamic> json) => RoofDimensions(
        length: (json['length'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        baseHeight: (json['baseHeight'] as num).toDouble(),
        pitch1: (json['pitch1'] as num).toDouble(),
        pitch2: (json['pitch2'] as num?)?.toDouble(),
        orientation: (json['orientation'] as num).toDouble(),
      );
}

class RoofSurface {
  final String id;
  final List<Coordinate3D> vertices; // Ordered vertices defining the polygon in 3D space
  final double tilt; // Degrees from horizontal
  final double azimuth; // Compass direction the surface faces (0-360, N=0, E=90)

  const RoofSurface({
    required this.id,
    required this.vertices,
    required this.tilt,
    required this.azimuth,
  });

  bool isPointOnSurface(Coordinate3D point) {
    // TODO: Implement point-in-polygon test for 3D surface (complex)
    // This would likely involve projecting to 2D plane of surface first.
    return true; // Placeholder
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vertices': vertices.map((v) => v.toJson()).toList(),
        'tilt': tilt,
        'azimuth': azimuth,
      };

  static RoofSurface fromJson(Map<dynamic, dynamic> json) => RoofSurface(
        id: json['id'] as String,
        vertices: (json['vertices'] as List<dynamic>)
            .map((v) => Coordinate3D.fromJson(v as Map<dynamic, dynamic>))
            .toList(),
        tilt: (json['tilt'] as num).toDouble(),
        azimuth: (json['azimuth'] as num).toDouble(),
      );
}

class RoofObstacle {
  final String id;
  final ObstacleType type;
  final Coordinate3D position; // Base center or reference point of the obstacle
  // Dimensions could be a Map<String, double> for flexibility, e.g. {'radius':x, 'height':y} or {'length':x, 'width':y, 'height':z}
  final Map<String, double> dimensions;

  const RoofObstacle({
    required this.id,
    required this.type,
    required this.position,
    required this.dimensions,
  });

  List<Coordinate3D> getShadowPolygon(Coordinate3D sunVector) {
    // TODO: Implement shadow projection based on obstacle shape, position, dimensions, and sun vector.
    // This is highly complex. For a simple box: project vertices. For cylinder: project top ellipse and sides.
    return []; // Placeholder
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString().split('.').last, // Store enum as string
        'position': position.toJson(),
        'dimensions': dimensions,
      };

  static ObstacleType _obstacleTypeFromString(String typeStr) {
    return ObstacleType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => ObstacleType.chimney, // Default or throw error
    );
  }
  static RoofObstacle fromJson(String key, Map<dynamic, dynamic> json) => RoofObstacle(
        id: key, // Assuming key from RTDB is the ID
        type: _obstacleTypeFromString(json['type'] as String),
        position: Coordinate3D.fromJson(json['position'] as Map<dynamic, dynamic>),
        dimensions: Map<String, double>.from(
          (json['dimensions'] as Map<dynamic,dynamic>).map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble())
          )
        ),
      );
}

class Roof {
  final String id; // e.g., simulationId_roof
  final RoofType overallType;
  final RoofDimensions mainDimensions;
  final List<RoofSurface> surfaces; // Could be auto-generated from type/dimensions or custom
  final List<RoofObstacle> obstacles;
  final bool hasTemporaryRoofExtension; // For future features

  const Roof({
    required this.id,
    required this.overallType,
    required this.mainDimensions,
    this.surfaces = const [],
    this.obstacles = const [],
    this.hasTemporaryRoofExtension = false,
  });

  // Methods to add/modify surfaces/obstacles would return a new Roof instance (immutability)
  Roof addSurface(RoofSurface surface) {
    return Roof(id: id, overallType: overallType, mainDimensions: mainDimensions,
                surfaces: [...surfaces, surface], obstacles: obstacles,
                hasTemporaryRoofExtension: hasTemporaryRoofExtension);
  }
  Roof addObstacle(RoofObstacle obstacle) {
     return Roof(id: id, overallType: overallType, mainDimensions: mainDimensions,
                surfaces: surfaces, obstacles: [...obstacles, obstacle],
                hasTemporaryRoofExtension: hasTemporaryRoofExtension);
  }
   Roof copyWith({
    String? id,
    RoofType? overallType,
    RoofDimensions? mainDimensions,
    List<RoofSurface>? surfaces,
    List<RoofObstacle>? obstacles,
    bool? hasTemporaryRoofExtension,
  }) {
    return Roof(
      id: id ?? this.id,
      overallType: overallType ?? this.overallType,
      mainDimensions: mainDimensions ?? this.mainDimensions,
      surfaces: surfaces ?? this.surfaces,
      obstacles: obstacles ?? this.obstacles,
      hasTemporaryRoofExtension: hasTemporaryRoofExtension ?? this.hasTemporaryRoofExtension,
    );
  }


  Map<String, dynamic> toJson() => {
        'id': id,
        'overallType': overallType.toString().split('.').last,
        'mainDimensions': mainDimensions.toJson(),
        'surfaces': surfaces.map((s) => s.toJson()).toList(),
        // Obstacles might be stored in a separate node in RTDB for easier list management
        // 'obstacles': obstacles.map((o) => o.toJson()).toList(),
        'hasTemporaryRoofExtension': hasTemporaryRoofExtension,
      };
  static RoofType _roofTypeFromString(String typeStr) {
    return RoofType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => RoofType.custom,
    );
  }

  // fromJson for Roof. Obstacles will be loaded separately by SimulationController/Service
  static Roof fromJson(Map<dynamic, dynamic> json, List<RoofObstacle> loadedObstacles) => Roof(
        id: json['id'] as String,
        overallType: _roofTypeFromString(json['overallType'] as String),
        mainDimensions: RoofDimensions.fromJson(json['mainDimensions'] as Map<dynamic, dynamic>),
        surfaces: (json['surfaces'] as List<dynamic>? ?? [])
            .map((s) => RoofSurface.fromJson(s as Map<dynamic, dynamic>))
            .toList(),
        obstacles: loadedObstacles, // Pass pre-loaded obstacles
        hasTemporaryRoofExtension: json['hasTemporaryRoofExtension'] as bool? ?? false,
      );
  
  // Default Roof for initialization
  static Roof defaultRoof(String id) => Roof(
    id: id,
    overallType: RoofType.gabled,
    mainDimensions: RoofDimensions(length: 10, width: 8, baseHeight: 3, pitch1: 30, orientation: 180),
    // Auto-generate some surfaces for default gabled roof (simplified)
    surfaces: [
      RoofSurface(id: "${id}_s1", vertices: [Coordinate3D(0,0,3), Coordinate3D(10,0,3), Coordinate3D(10,4,3+4*math.tan(30*math.pi/180)), Coordinate3D(0,4,3+4*math.tan(30*math.pi/180))], tilt: 30, azimuth: 180),
      RoofSurface(id: "${id}_s2", vertices: [Coordinate3D(0,8,3), Coordinate3D(10,8,3), Coordinate3D(10,4,3+4*math.tan(30*math.pi/180)), Coordinate3D(0,4,3+4*math.tan(30*math.pi/180))], tilt: 30, azimuth: 0),
    ]
  );
}

class PanelSpecifications {
  final String id; // Unique ID for this spec, e.g., manufacturer_model
  final String modelName;
  final String manufacturer;
  final double nominalPower; // Wp (Watts-peak)
  final double efficiencySTC; // Standard Test Conditions efficiency (0.0 - 1.0)
  final double tempCoeffPmax; // %/°C, usually negative
  final double length; // meters
  final double width; // meters
  final double annualDegradationRate; // e.g., 0.005 for 0.5%

  const PanelSpecifications({
    required this.id,
    required this.modelName,
    required this.manufacturer,
    required this.nominalPower,
    required this.efficiencySTC,
    required this.tempCoeffPmax,
    required this.length,
    required this.width,
    required this.annualDegradationRate,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'modelName': modelName, 'manufacturer': manufacturer,
        'nominalPower': nominalPower, 'efficiencySTC': efficiencySTC,
        'tempCoeffPmax': tempCoeffPmax, 'length': length, 'width': width,
        'annualDegradationRate': annualDegradationRate,
      };

  static PanelSpecifications fromJson(String key, Map<dynamic, dynamic> json) => PanelSpecifications(
        id: key, // In RTDB, the key is the ID
        modelName: json['modelName'] as String,
        manufacturer: json['manufacturer'] as String,
        nominalPower: (json['nominalPower'] as num).toDouble(),
        efficiencySTC: (json['efficiencySTC'] as num).toDouble(),
        tempCoeffPmax: (json['tempCoeffPmax'] as num).toDouble(),
        length: (json['length'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        annualDegradationRate: (json['annualDegradationRate'] as num).toDouble(),
      );
}

class PanelPlacementInfo {
  final String panelSpecId;
  final String roofSurfaceId;
  final Coordinate3D positionOnSurface; // Top-left corner, relative to surface origin or absolute world coords
  final double rotationOnSurface; // Degrees, around Z-axis perpendicular to surface
  final double? customTiltOffset; // Degrees, relative to surface tilt
  final double? customAzimuthOffset; // Degrees, relative to surface azimuth

  const PanelPlacementInfo({
    required this.panelSpecId,
    required this.roofSurfaceId,
    required this.positionOnSurface,
    this.rotationOnSurface = 0.0,
    this.customTiltOffset,
    this.customAzimuthOffset,
  });

  Map<String, dynamic> toJson() => {
        'panelSpecId': panelSpecId, 'roofSurfaceId': roofSurfaceId,
        'positionOnSurface': positionOnSurface.toJson(),
        'rotationOnSurface': rotationOnSurface,
        'customTiltOffset': customTiltOffset,
        'customAzimuthOffset': customAzimuthOffset,
      };

  static PanelPlacementInfo fromJson(Map<dynamic, dynamic> json) => PanelPlacementInfo(
        panelSpecId: json['panelSpecId'] as String,
        roofSurfaceId: json['roofSurfaceId'] as String,
        positionOnSurface: Coordinate3D.fromJson(json['positionOnSurface'] as Map<dynamic, dynamic>),
        rotationOnSurface: (json['rotationOnSurface'] as num?)?.toDouble() ?? 0.0,
        customTiltOffset: (json['customTiltOffset'] as num?)?.toDouble(),
        customAzimuthOffset: (json['customAzimuthOffset'] as num?)?.toDouble(),
      );
}

class SolarPanel {
  final String id; // Unique ID for this placed panel instance
  final PanelPlacementInfo placementInfo;
  final DateTime installationDate;

  // Mutable state, often managed by SimulationController or a wrapper
  PanelStatus currentStatus;
  double currentOutputWh;
  double accumulatedOutputKWh;
  double currentTemperature; // Cell temperature
  double effectiveEfficiency;
  String? faultDetails;

  SolarPanel({
    required this.id,
    required this.placementInfo,
    required this.installationDate,
    this.currentStatus = PanelStatus.active,
    this.currentOutputWh = 0.0,
    this.accumulatedOutputKWh = 0.0,
    this.currentTemperature = 25.0, // Assume STC initially
    this.effectiveEfficiency = 0.0, // Will be calculated
    this.faultDetails,
  });

  SolarPanel copyWith({
    String? id, PanelPlacementInfo? placementInfo, DateTime? installationDate,
    PanelStatus? currentStatus, double? currentOutputWh, double? accumulatedOutputKWh,
    double? currentTemperature, double? effectiveEfficiency, String? faultDetails,
    bool clearFaultDetails = false,
  }) {
    return SolarPanel(
      id: id ?? this.id,
      placementInfo: placementInfo ?? this.placementInfo,
      installationDate: installationDate ?? this.installationDate,
      currentStatus: currentStatus ?? this.currentStatus,
      currentOutputWh: currentOutputWh ?? this.currentOutputWh,
      accumulatedOutputKWh: accumulatedOutputKWh ?? this.accumulatedOutputKWh,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      effectiveEfficiency: effectiveEfficiency ?? this.effectiveEfficiency,
      faultDetails: clearFaultDetails ? null : faultDetails ?? this.faultDetails,
    );
  }

  Map<String, dynamic> toJson() => {
        // 'id': id, // ID is key in RTDB
        'placementInfo': placementInfo.toJson(),
        'installationDate': installationDate.toIso8601String(),
        'currentStatus': currentStatus.toString().split('.').last,
        'currentOutputWh': currentOutputWh,
        'accumulatedOutputKWh': accumulatedOutputKWh,
        'currentTemperature': currentTemperature,
        'effectiveEfficiency': effectiveEfficiency,
        'faultDetails': faultDetails,
      };

  static PanelStatus _panelStatusFromString(String statusStr) {
    return PanelStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => PanelStatus.active,
    );
  }
  static SolarPanel fromJson(String key, Map<dynamic, dynamic> json) => SolarPanel(
        id: key, // Key from RTDB
        placementInfo: PanelPlacementInfo.fromJson(json['placementInfo'] as Map<dynamic, dynamic>),
        installationDate: DateTime.parse(json['installationDate'] as String),
        currentStatus: _panelStatusFromString(json['currentStatus'] as String? ?? 'active'),
        currentOutputWh: (json['currentOutputWh'] as num?)?.toDouble() ?? 0.0,
        accumulatedOutputKWh: (json['accumulatedOutputKWh'] as num?)?.toDouble() ?? 0.0,
        currentTemperature: (json['currentTemperature'] as num?)?.toDouble() ?? 25.0,
        effectiveEfficiency: (json['effectiveEfficiency'] as num?)?.toDouble() ?? 0.0,
        faultDetails: json['faultDetails'] as String?,
      );
}

class SimulationParameters {
  final DateTime simulationDate;
  final double latitude;
  final double longitude;
  // Example: TimeOfDay string "HH:MM" to temperature
  final Map<String, double> ambientTemperatureProfile; // { "00:00": 15.0, "01:00": 14.5, ... }
  final double albedo; // Ground reflectivity (0.0 - 1.0)
  final double soilingLossFactor; // (0.0 - 1.0, e.g., 0.98 for 2% loss)
  final double inverterEfficiency; // (0.0 - 1.0)
  // Add other system losses if needed: cableLossFactor, mismatchLossFactor, etc.

  const SimulationParameters({
    required this.simulationDate,
    required this.latitude,
    required this.longitude,
    this.ambientTemperatureProfile = const {}, // Should be populated
    this.albedo = 0.2,
    this.soilingLossFactor = 0.98,
    this.inverterEfficiency = 0.96,
  });

  SimulationParameters copyWith({
    DateTime? simulationDate, double? latitude, double? longitude,
    Map<String, double>? ambientTemperatureProfile, double? albedo,
    double? soilingLossFactor, double? inverterEfficiency,
  }) {
    return SimulationParameters(
      simulationDate: simulationDate ?? this.simulationDate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ambientTemperatureProfile: ambientTemperatureProfile ?? this.ambientTemperatureProfile,
      albedo: albedo ?? this.albedo,
      soilingLossFactor: soilingLossFactor ?? this.soilingLossFactor,
      inverterEfficiency: inverterEfficiency ?? this.inverterEfficiency,
    );
  }

  Map<String, dynamic> toJson() => {
        'simulationDate': simulationDate.toIso8601String(),
        'latitude': latitude, 'longitude': longitude,
        'ambientTemperatureProfile': ambientTemperatureProfile,
        'albedo': albedo, 'soilingLossFactor': soilingLossFactor,
        'inverterEfficiency': inverterEfficiency,
      };

  static SimulationParameters fromJson(Map<dynamic, dynamic> json) => SimulationParameters(
        simulationDate: DateTime.parse(json['simulationDate'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        ambientTemperatureProfile: Map<String, double>.from(
            (json['ambientTemperatureProfile'] as Map<dynamic,dynamic>? ?? {}).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble())
        ),
        albedo: (json['albedo'] as num?)?.toDouble() ?? 0.2,
        soilingLossFactor: (json['soilingLossFactor'] as num?)?.toDouble() ?? 0.98,
        inverterEfficiency: (json['inverterEfficiency'] as num?)?.toDouble() ?? 0.96,
      );
  
  static SimulationParameters defaultParameters() => SimulationParameters(
    simulationDate: DateTime.now(),
    latitude: 34.0522, // Default to LA
    longitude: -118.2437,
    ambientTemperatureProfile: _defaultTempProfile(),
  );

  static Map<String, double> _defaultTempProfile() {
    Map<String, double> profile = {};
    for (int hour = 0; hour < 24; hour++) {
      // Simplified sinusoidal profile peaking at 2 PM
      double temp = 15 + 10 * math.sin((hour - 8) * math.pi / 12);
      profile['${hour.toString().padLeft(2, '0')}:00'] = temp.clamp(10, 35);
    }
    return profile;
  }
}

class SimulationTimeStepResult {
  final DateTime timestamp;
  final Map<String, double> panelOutputsWh; // Panel ID to Wh output for this step
  final double totalSystemOutputWh; // AC output after inverter
  final double sunAltitude; // Degrees
  final double sunAzimuth; // Degrees
  // POA Irradiance (Total) for each panel - useful for diagnostics
  final Map<String, double> poaIrradianceMap; // Panel ID to W/m^2

  const SimulationTimeStepResult({
    required this.timestamp,
    required this.panelOutputsWh,
    required this.totalSystemOutputWh,
    required this.sunAltitude,
    required this.sunAzimuth,
    required this.poaIrradianceMap,
  });

   Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'panelOutputsWh': panelOutputsWh,
        'totalSystemOutputWh': totalSystemOutputWh,
        'sunAltitude': sunAltitude,
        'sunAzimuth': sunAzimuth,
        'poaIrradianceMap': poaIrradianceMap,
      };

  static SimulationTimeStepResult fromJson(Map<dynamic, dynamic> json) => SimulationTimeStepResult(
        timestamp: DateTime.parse(json['timestamp'] as String),
        panelOutputsWh: Map<String, double>.from(
          (json['panelOutputsWh'] as Map<dynamic,dynamic>).map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble())
        ),
        totalSystemOutputWh: (json['totalSystemOutputWh'] as num).toDouble(),
        sunAltitude: (json['sunAltitude'] as num).toDouble(),
        sunAzimuth: (json['sunAzimuth'] as num).toDouble(),
        poaIrradianceMap: Map<String, double>.from(
          (json['poaIrradianceMap'] as Map<dynamic,dynamic>).map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble())
        ),
      );
}

class SimulationState {
  final String userId;
  final String simulationName;
  final Roof? roof;
  final List<PanelSpecifications> availablePanelSpecs; // Loaded from a general DB location
  final List<SolarPanel> placedPanels;
  final SimulationParameters parameters;
  final List<SimulationTimeStepResult>? dailyTimeSeriesResults; // Results for the last run day
  final double? totalDailyYieldKWh; // Sum of dailyTimeSeriesResults
  final DateTime lastModified;

  const SimulationState({
    required this.userId,
    required this.simulationName,
    this.roof,
    this.availablePanelSpecs = const [],
    this.placedPanels = const [],
    required this.parameters,
    this.dailyTimeSeriesResults,
    this.totalDailyYieldKWh,
    required this.lastModified,
  });

  SimulationState copyWith({
    String? userId, String? simulationName, Roof? roof,
    List<PanelSpecifications>? availablePanelSpecs, List<SolarPanel>? placedPanels,
    SimulationParameters? parameters, List<SimulationTimeStepResult>? dailyTimeSeriesResults,
    double? totalDailyYieldKWh, DateTime? lastModified,
    bool clearResults = false,
  }) {
    return SimulationState(
      userId: userId ?? this.userId,
      simulationName: simulationName ?? this.simulationName,
      roof: roof ?? this.roof,
      availablePanelSpecs: availablePanelSpecs ?? this.availablePanelSpecs,
      placedPanels: placedPanels ?? this.placedPanels,
      parameters: parameters ?? this.parameters,
      dailyTimeSeriesResults: clearResults ? null : dailyTimeSeriesResults ?? this.dailyTimeSeriesResults,
      totalDailyYieldKWh: clearResults ? null : totalDailyYieldKWh ?? this.totalDailyYieldKWh,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  // toJson and fromJson for SimulationState are complex because sub-objects
  // (roof, panels, obstacles, panelSpecs) might be stored in different RTDB nodes.
  // The SimulationFirebaseService will handle assembling/disassembling this.
  // This toJson here is conceptual for the main simulation node.
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'simulationName': simulationName,
        'parameters': parameters.toJson(),
        // roofId, panelSpecIds, placedPanelIds might be stored instead of full objects
        // 'roofId': roof?.id,
        'lastModified': lastModified.toIso8601String(),
        'totalDailyYieldKWh': totalDailyYieldKWh,
        // Time series results might also be stored in a separate large node if too big
      };

  // fromJson would be called by the service after fetching components
  static SimulationState fromJson(Map<dynamic, dynamic> json, {
    required Roof loadedRoof,
    required List<SolarPanel> loadedPanels,
    required List<PanelSpecifications> loadedPanelSpecs,
    required List<SimulationTimeStepResult> loadedResults, // if any
  }) => SimulationState(
        userId: json['userId'] as String,
        simulationName: json['simulationName'] as String,
        roof: loadedRoof,
        availablePanelSpecs: loadedPanelSpecs,
        placedPanels: loadedPanels,
        parameters: SimulationParameters.fromJson(json['parameters'] as Map<dynamic, dynamic>),
        dailyTimeSeriesResults: loadedResults.isNotEmpty ? loadedResults : null,
        totalDailyYieldKWh: (json['totalDailyYieldKWh'] as num?)?.toDouble(),
        lastModified: DateTime.parse(json['lastModified'] as String),
      );

  static SimulationState defaultState(String userId, String simName, List<PanelSpecifications> specs) {
    return SimulationState(
      userId: userId,
      simulationName: simName,
      roof: Roof.defaultRoof("${simName}_roof"),
      availablePanelSpecs: specs,
      placedPanels: [],
      parameters: SimulationParameters.defaultParameters(),
      lastModified: DateTime.now(),
    );
  }
}