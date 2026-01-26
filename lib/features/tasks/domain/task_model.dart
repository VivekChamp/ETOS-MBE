class Task {
  final String name;
  final String subject;
  final String status;
  final String priority;
  final String owner;
  final String? assignedTo;
  final String? expStartDate;
  final String? expEndDate;
  final String? description;
  final String? project;

  Task({
    required this.name,
    required this.subject,
    required this.status,
    required this.priority,
    required this.owner,
    this.assignedTo,
    this.expStartDate,
    this.expEndDate,
    this.description,
    this.project,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      name: json['name'] ?? '',
      subject: json['subject'] ?? 'No Subject',
      status: json['status'] ?? 'Open',
      priority: json['priority'] ?? 'Medium',
      owner: json['owner'] ?? '',
      assignedTo: json['assigned_to'],
      expStartDate: json['exp_start_date'],
      expEndDate: json['exp_end_date'],
      description: json['description'],
      project: json['project'],
    );
  }
}
