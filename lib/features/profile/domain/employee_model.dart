class Employee {
  final String name; // ID like HR-EMP-00010
  final String employeeName;
  final String? image;
  final String? designation;
  final String? department;
  final String? mobileNo;
  final String? companyEmail;
  final String? status;
  final String? dateOfJoining;
  final String? dateOfBirth;
  final String? gender;
  final String? company;

  Employee({
    required this.name,
    required this.employeeName,
    this.image,
    this.designation,
    this.department,
    this.mobileNo,
    this.companyEmail,
    this.status,
    this.dateOfJoining,
    this.dateOfBirth,
    this.gender,
    this.company,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name'] ?? '',
      employeeName: json['employee_name'] ?? '',
      image: json['image'],
      designation: json['designation'],
      department: json['department'],
      mobileNo: json['mobile_no'] ?? json['cell_number'],
      companyEmail: json['company_email'] ?? json['user_id'],
      status: json['status'],
      dateOfJoining: json['date_of_joining'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      company: json['company'],
    );
  }
}
