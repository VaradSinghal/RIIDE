import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── H3 Zone Data Model ─────────────────────────────────────────────
class H3ZoneData {
  final String zone;
  final String h3Index;
  final double lat;
  final double lng;
  final int riskScore;
  final double historicalWeather; // 30%
  final double terrainDrainage;  // 25%
  final double historicalClaims; // 25%
  final double realtimeConditions; // 20%
  final String rainfall;
  final int elevation;
  final double drainageScore;
  final int floodEvents;
  final int disruptionDays;

  H3ZoneData({
    required this.zone,
    required this.h3Index,
    required this.lat,
    required this.lng,
    required this.riskScore,
    required this.historicalWeather,
    required this.terrainDrainage,
    required this.historicalClaims,
    required this.realtimeConditions,
    required this.rainfall,
    required this.elevation,
    required this.drainageScore,
    required this.floodEvents,
    required this.disruptionDays,
  });

  String get riskLabel {
    if (riskScore >= 80) return 'Critical';
    if (riskScore >= 60) return 'High';
    if (riskScore >= 40) return 'Moderate';
    return 'Low';
  }

  Color get riskColor {
    if (riskScore >= 80) return const Color(0xFFE84393);
    if (riskScore >= 60) return AppColors.danger;
    if (riskScore >= 40) return AppColors.warning;
    return AppColors.success;
  }
}

// ─── Static H3 Data for Chennai (from zones.csv) ─────────────────────
final List<H3ZoneData> _chennaiH3Zones = [
  H3ZoneData(zone: 'Tambaram', h3Index: '8a2a1072c59ffff', lat: 12.925, lng: 80.128, riskScore: 82, historicalWeather: 28.0, terrainDrainage: 23.0, historicalClaims: 22.0, realtimeConditions: 9.0, rainfall: '38mm', elevation: 3, drainageScore: 0.32, floodEvents: 20, disruptionDays: 45),
  H3ZoneData(zone: 'Porur', h3Index: '8a2a1072c4bffff', lat: 13.039, lng: 80.157, riskScore: 74, historicalWeather: 22.0, terrainDrainage: 22.0, historicalClaims: 18.0, realtimeConditions: 12.0, rainfall: '25mm', elevation: 12, drainageScore: 0.25, floodEvents: 11, disruptionDays: 27),
  H3ZoneData(zone: 'Adyar', h3Index: '8a2a1072c67ffff', lat: 13.006, lng: 80.257, riskScore: 65, historicalWeather: 20.0, terrainDrainage: 16.0, historicalClaims: 18.0, realtimeConditions: 11.0, rainfall: '12mm', elevation: 37, drainageScore: 0.34, floodEvents: 16, disruptionDays: 18),
  H3ZoneData(zone: 'Velachery', h3Index: '8a2a1072c73ffff', lat: 12.981, lng: 80.221, riskScore: 48, historicalWeather: 12.0, terrainDrainage: 14.0, historicalClaims: 12.0, realtimeConditions: 10.0, rainfall: '8mm', elevation: 42, drainageScore: 0.35, floodEvents: 5, disruptionDays: 22),
  H3ZoneData(zone: 'T. Nagar', h3Index: '8a2a1072c53ffff', lat: 13.041, lng: 80.234, riskScore: 28, historicalWeather: 6.0, terrainDrainage: 4.0, historicalClaims: 8.0, realtimeConditions: 10.0, rainfall: '3mm', elevation: 28, drainageScore: 0.85, floodEvents: 2, disruptionDays: 11),
  H3ZoneData(zone: 'Mylapore', h3Index: '8a2a1072c5bffff', lat: 13.034, lng: 80.267, riskScore: 22, historicalWeather: 4.0, terrainDrainage: 6.0, historicalClaims: 4.0, realtimeConditions: 8.0, rainfall: '1mm', elevation: 28, drainageScore: 0.61, floodEvents: 0, disruptionDays: 6),
  H3ZoneData(zone: 'Anna Nagar', h3Index: '8a2a1072c47ffff', lat: 13.086, lng: 80.210, riskScore: 18, historicalWeather: 3.0, terrainDrainage: 2.0, historicalClaims: 5.0, realtimeConditions: 8.0, rainfall: '0mm', elevation: 84, drainageScore: 0.83, floodEvents: 1, disruptionDays: 7),
  H3ZoneData(zone: 'Guindy', h3Index: '8a2a1072c6bffff', lat: 13.009, lng: 80.212, riskScore: 30, historicalWeather: 6.0, terrainDrainage: 6.0, historicalClaims: 10.0, realtimeConditions: 8.0, rainfall: '4mm', elevation: 89, drainageScore: 0.72, floodEvents: 1, disruptionDays: 9),
  H3ZoneData(zone: 'Sholinganallur', h3Index: '8a2a1072c77ffff', lat: 12.901, lng: 80.228, riskScore: 15, historicalWeather: 3.0, terrainDrainage: 1.0, historicalClaims: 4.0, realtimeConditions: 7.0, rainfall: '0mm', elevation: 91, drainageScore: 0.86, floodEvents: 3, disruptionDays: 5),
  H3ZoneData(zone: 'Chromepet', h3Index: '8a2a1072c63ffff', lat: 12.952, lng: 80.141, riskScore: 12, historicalWeather: 2.0, terrainDrainage: 1.0, historicalClaims: 2.0, realtimeConditions: 7.0, rainfall: '0mm', elevation: 90, drainageScore: 0.83, floodEvents: 0, disruptionDays: 4),
];

// ─── Screen ──────────────────────────────────────────────────────────
class RiskMapScreen extends StatefulWidget {
  const RiskMapScreen({super.key});

  @override
  State<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends State<RiskMapScreen> with SingleTickerProviderStateMixin {
  H3ZoneData? _selectedZone;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedZones = List<H3ZoneData>.from(_chennaiH3Zones)
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // ── Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hexagon_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('H3 Risk Map', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Uber H3 hexagonal geospatial indexing', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Hex Grid Map
              _buildH3HexMap(sortedZones),
              const SizedBox(height: 8),
              _buildLegend(),
              const SizedBox(height: 20),

              // ── Risk Layers Breakdown (underwriting explanation)
              _buildRiskLayersCard(),
              const SizedBox(height: 20),

              // ── Selected Zone Detail (tap a hex to expand)
              if (_selectedZone != null) ...[
                _buildZoneDetailCard(_selectedZone!),
                const SizedBox(height: 20),
              ],

              // ── All Zones List
              const Text('Zone Risk Scores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('${sortedZones.length} H3 hexagonal zones · Chennai', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...sortedZones.map((z) => _buildZoneRow(z)),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ─── H3 Hex Grid Map (Custom Painted) ──────────────────────────────
  Widget _buildH3HexMap(List<H3ZoneData> zones) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0B0D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Hex grid background
            CustomPaint(
              size: const Size(double.infinity, 300),
              painter: _H3MapPainter(zones: zones, selectedZone: _selectedZone),
            ),
            // Zone labels
            ..._buildZoneLabels(zones),
            // Top-left badge
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hexagon_outlined, color: AppColors.primary, size: 14),
                    SizedBox(width: 6),
                    Text('H3 Res-7 · Chennai', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ],
                ),
              ),
            ),
            // Bottom-right data source
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('IMD · OpenWeather · SRTM', style: TextStyle(fontSize: 9, color: Colors.white38)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildZoneLabels(List<H3ZoneData> zones) {
    // Map each zone to a position within the 300px container
    // We use a simple grid layout approach
    final positions = <String, Offset>{
      'Tambaram':       const Offset(0.18, 0.75),
      'Porur':          const Offset(0.12, 0.40),
      'Adyar':          const Offset(0.55, 0.55),
      'Velachery':      const Offset(0.35, 0.60),
      'T. Nagar':       const Offset(0.40, 0.30),
      'Mylapore':       const Offset(0.70, 0.35),
      'Anna Nagar':     const Offset(0.30, 0.12),
      'Guindy':         const Offset(0.55, 0.18),
      'Sholinganallur': const Offset(0.78, 0.72),
      'Chromepet':      const Offset(0.15, 0.58),
    };

    return zones.map((z) {
      final pos = positions[z.zone];
      if (pos == null) return const SizedBox.shrink();
      return Positioned(
        left: pos.dx * MediaQuery.of(context).size.width * 0.85,
        top: pos.dy * 280,
        child: GestureDetector(
          onTap: () => setState(() => _selectedZone = _selectedZone == z ? null : z),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final isSelected = _selectedZone == z;
              final scale = isSelected ? 1.0 + _pulseController.value * 0.08 : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: z.riskColor.withValues(alpha: isSelected ? 0.9 : 0.75),
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                    boxShadow: [BoxShadow(color: z.riskColor.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(z.zone, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('${z.riskScore}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }

  // ─── Risk Layers Card ──────────────────────────────────────────────
  Widget _buildRiskLayersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.layers_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Underwriting Risk Layers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('4 weighted data layers per H3 hex', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _riskLayerRow('Historical Weather', '30%', Icons.cloud_rounded, AppColors.primary, 'IMD, OpenWeather — flood, cyclone, and heavy rain archives'),
          const SizedBox(height: 12),
          _riskLayerRow('Terrain & Drainage', '25%', Icons.terrain_rounded, AppColors.warning, 'OSM road density, SRTM elevation, drainage capacity'),
          const SizedBox(height: 12),
          _riskLayerRow('Historical Claims', '25%', Icons.receipt_long_rounded, AppColors.danger, 'Past claims volume, payout frequency per zone'),
          const SizedBox(height: 12),
          _riskLayerRow('Real-Time Conditions', '20%', Icons.sensors_rounded, AppColors.success, 'Live weather + AQI + active alerts from feeds'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.functions_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Zone Risk Score = (0.30 × Historical Weather) + (0.25 × Terrain) + (0.25 × Claims) + (0.20 × Real-Time)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary, height: 1.4, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskLayerRow(String label, String weight, IconData icon, Color color, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(weight, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Selected Zone Detail Card ─────────────────────────────────────
  Widget _buildZoneDetailCard(H3ZoneData z) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: z.riskColor.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: z.riskColor.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: z.riskColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text('${z.riskScore}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: z.riskColor))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(z.zone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Row(
                      children: [
                        Flexible(child: Text(z.riskLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: z.riskColor))),
                        const SizedBox(width: 8),
                        const Text('·', style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        Flexible(child: Text(z.h3Index, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                onPressed: () => setState(() => _selectedZone = null),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Risk layer bars
          _detailBar('Historical Weather', z.historicalWeather, 30.0, AppColors.primary),
          const SizedBox(height: 10),
          _detailBar('Terrain & Drainage', z.terrainDrainage, 25.0, AppColors.warning),
          const SizedBox(height: 10),
          _detailBar('Historical Claims', z.historicalClaims, 25.0, AppColors.danger),
          const SizedBox(height: 10),
          _detailBar('Real-Time Conditions', z.realtimeConditions, 20.0, AppColors.success),
          const SizedBox(height: 20),

          // Stats grid
          Row(
            children: [
              _statChip('Elevation', '${z.elevation}m', Icons.height_rounded),
              const SizedBox(width: 8),
              _statChip('Drainage', '${(z.drainageScore * 100).toInt()}%', Icons.water_drop_rounded),
              const SizedBox(width: 8),
              _statChip('Flood Events', '${z.floodEvents}', Icons.flood_rounded),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statChip('Disruption Days', '${z.disruptionDays}', Icons.warning_amber_rounded),
              const SizedBox(width: 8),
              _statChip('Rainfall', z.rainfall, Icons.grain_rounded),
              const SizedBox(width: 8),
              _statChip('Coords', '${z.lat.toStringAsFixed(2)}°N', Icons.location_on_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailBar(String label, double value, double maxValue, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text('${value.toInt()} / ${maxValue.toInt()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / maxValue,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ─── Legend ─────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 6,
        children: [
          _legendItem(AppColors.success, 'Low (0–39)'),
          _legendItem(AppColors.warning, 'Moderate (40–59)'),
          _legendItem(AppColors.danger, 'High (60–79)'),
          _legendItem(const Color(0xFFE84393), 'Critical (80+)'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }

  // ─── Zone List ─────────────────────────────────────────────────────
  Widget _buildZoneRow(H3ZoneData z) {
    final isSelected = _selectedZone == z;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedZone = isSelected ? null : z),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? z.riskColor.withValues(alpha: 0.05) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? z.riskColor.withValues(alpha: 0.3) : AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: z.riskColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('${z.riskScore}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: z.riskColor))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(z.zone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Rain: ${z.rainfall} · Elev: ${z.elevation}m · Floods: ${z.floodEvents}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: z.riskColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(z.riskLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: z.riskColor)),
                  ),
                  const SizedBox(height: 4),
                  Text(z.h3Index.substring(0, 10), style: const TextStyle(fontSize: 8, color: AppColors.textMuted, fontFamily: 'monospace')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter: H3 Map ──────────────────────────────────────────
class _H3MapPainter extends CustomPainter {
  final List<H3ZoneData> zones;
  final H3ZoneData? selectedZone;

  _H3MapPainter({required this.zones, this.selectedZone});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark map background grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexSize = 24.0;
    final rows = (size.height / (hexSize * 1.5)).ceil() + 1;
    final cols = (size.width / (hexSize * 1.73)).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final offset = row.isOdd ? hexSize * 0.87 : 0.0;
        final cx = col * hexSize * 1.73 + offset;
        final cy = row * hexSize * 1.5;
        _drawHex(canvas, Offset(cx, cy), hexSize, gridPaint);
      }
    }

    // Risk-colored hexes at mapped positions
    final zonePositions = <String, Offset>{
      'Tambaram':       Offset(size.width * 0.22, size.height * 0.78),
      'Porur':          Offset(size.width * 0.16, size.height * 0.43),
      'Adyar':          Offset(size.width * 0.58, size.height * 0.58),
      'Velachery':      Offset(size.width * 0.38, size.height * 0.63),
      'T. Nagar':       Offset(size.width * 0.43, size.height * 0.33),
      'Mylapore':       Offset(size.width * 0.73, size.height * 0.38),
      'Anna Nagar':     Offset(size.width * 0.33, size.height * 0.15),
      'Guindy':         Offset(size.width * 0.58, size.height * 0.21),
      'Sholinganallur': Offset(size.width * 0.82, size.height * 0.75),
      'Chromepet':      Offset(size.width * 0.19, size.height * 0.61),
    };

    for (final zone in zones) {
      final pos = zonePositions[zone.zone];
      if (pos == null) continue;

      final fillPaint = Paint()
        ..color = zone.riskColor.withValues(alpha: selectedZone == zone ? 0.45 : 0.25)
        ..style = PaintingStyle.fill;
      _drawHex(canvas, pos, hexSize * 1.8, fillPaint);

      final borderPaint = Paint()
        ..color = zone.riskColor.withValues(alpha: selectedZone == zone ? 0.8 : 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selectedZone == zone ? 2.0 : 1.0;
      _drawHex(canvas, pos, hexSize * 1.8, borderPaint);
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final x = center.dx + size * 0.5 * cos(angle) * 1.73;
      final y = center.dy + size * 0.5 * sin(angle) * 1.73;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _H3MapPainter old) => old.selectedZone != selectedZone;
}
