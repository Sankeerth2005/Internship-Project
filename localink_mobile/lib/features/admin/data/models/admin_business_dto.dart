class AdminBusinessDto {
  final int id;
  final String name;
  final String category;
  final String description;
  final String? phone;
  final String? email;
  final String? address;
  final String status;
  final String? rejectionComment;

  AdminBusinessDto({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.phone,
    this.email,
    this.address,
    required this.status,
    this.rejectionComment,
  });

  factory AdminBusinessDto.fromJson(Map<String, dynamic> json) {
    return AdminBusinessDto(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      status: json['status'] ?? 'Pending',
      rejectionComment: json['rejectionComment'],
    );
  }
}
