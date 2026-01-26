class Project {
  final String name;
  final String projectName;
  final String status;
  final String projectType;
  final String priority;
  final double percentComplete;
  final String? expectedStartDate;
  final String? expectedEndDate;
  final String isActive; // Changed to String to handle "Yes"/"No"

  Project({
    required this.name,
    required this.projectName,
    required this.status,
    required this.projectType,
    required this.priority,
    required this.percentComplete,
    this.expectedStartDate,
    this.expectedEndDate,
    required this.isActive,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name']?.toString() ?? '',
      projectName: json['project_name']?.toString() ?? 'No Name',
      status: json['status']?.toString() ?? 'Open',
      projectType: json['project_type']?.toString() ?? 'Internal',
      priority: json['priority']?.toString() ?? 'Medium',
      percentComplete: _parseDouble(json['percent_complete']),
      expectedStartDate: json['expected_start_date']?.toString(),
      expectedEndDate: json['expected_end_date']?.toString(),
      isActive: json['is_active']?.toString() ?? 'Yes',
    );
  }

  // Helper to safely parse double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
