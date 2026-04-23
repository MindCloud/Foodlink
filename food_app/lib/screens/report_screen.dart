// lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/ima_api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? reportData;
  Uint8List? graphImage;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final data = await ImaApiService.generateReport();
      
      if (data != null) {
        // Decode base64 graph image
        Uint8List? imageBytes;
        if (data['graph'] != null) {
          imageBytes = base64Decode(data['graph']);
        }
        
        setState(() {
          reportData = data;
          graphImage = imageBytes;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to generate report";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IMA Evaluation Report"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorView()
              : _buildReportView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReport,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummarySection(),
          const SizedBox(height: 24),
          
          // Graph Image
          if (graphImage != null) _buildGraphSection(),
          const SizedBox(height: 24),
          
          // Detailed Metrics Table
          _buildMetricsTable(),
          const SizedBox(height: 24),
          
          // Method Comparison
          _buildMethodComparison(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Summary",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Total Donations",
                reportData!['total_donations'].toString(),
                Icons.inventory_2,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Total Charities",
                reportData!['total_charities'].toString(),
                Icons.business,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Adaptive Matches",
                reportData!['adaptive_matches'].toString(),
                Icons.psychology,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Avg Distance",
                "${reportData!['avg_distance'].toStringAsFixed(2)} km",
                Icons.route,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Evaluation Graphs",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              graphImage!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detailed Metrics",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              DataRow(cells: [
                const DataCell(Text('Total Donations')),
                DataCell(Text(reportData!['total_donations'].toString())),
              ]),
              DataRow(cells: [
                const DataCell(Text('Total Charities')),
                DataCell(Text(reportData!['total_charities'].toString())),
              ]),
              DataRow(cells: [
                const DataCell(Text('Adaptive IMA Matches')),
                DataCell(Text(reportData!['adaptive_matches'].toString())),
              ]),
              DataRow(cells: [
                const DataCell(Text('Nearest Baseline Matches')),
                DataCell(Text(reportData!['nearest_matches'].toString())),
              ]),
              DataRow(cells: [
                const DataCell(Text('Fairness Baseline Matches')),
                DataCell(Text(reportData!['fairness_matches'].toString())),
              ]),
              DataRow(cells: [
                const DataCell(Text('Average Distance')),
                DataCell(Text("${reportData!['avg_distance'].toStringAsFixed(2)} km")),
              ]),
              DataRow(cells: [
                const DataCell(Text('Average Spoilage Risk')),
                DataCell(Text("${(reportData!['avg_spoilage_risk'] * 100).toStringAsFixed(1)}%")),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodComparison() {
    final adaptive = reportData!['adaptive_matches'];
    final nearest = reportData!['nearest_matches'];
    final fairness = reportData!['fairness_matches'];
    final total = adaptive + nearest + fairness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Method Comparison",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProgressBar('Adaptive IMA', adaptive, total, Colors.purple),
                const SizedBox(height: 12),
                _buildProgressBar('Nearest Baseline', nearest, total, Colors.blue),
                const SizedBox(height: 12),
                _buildProgressBar('Fairness Baseline', fairness, total, Colors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text("$value (${percentage.toStringAsFixed(1)}%)"),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }
}
