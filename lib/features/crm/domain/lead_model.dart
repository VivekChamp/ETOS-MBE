class Lead {
  final String name;
  final String leadName;
  final String? companyName;
  final String? emailId;
  final String? mobileNo;
  final String status;
  final String? territory;
  final String? type; // Lead type field from backend

  Lead({
    required this.name,
    required this.leadName,
    this.companyName,
    this.emailId,
    this.mobileNo,
    required this.status,
    this.territory,
    this.type,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      name: json['name'] ?? '',
      leadName: json['lead_name'] ?? 'Unknown',
      companyName: json['company_name'],
      emailId: json['email_id'],
      mobileNo: json['mobile_no'],
      status: json['status'] ?? 'Lead',
      territory: json['territory'],
      type: json['type'], // Fetching type field
    );
  }
}
