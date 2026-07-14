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

  final bool isTemporaryClosurePending;
  final String? temporaryClosureReason;
  final int? temporaryClosureDays;
  final String? ownerName;

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
    this.isTemporaryClosurePending = false,
    this.temporaryClosureReason,
    this.temporaryClosureDays,
    this.ownerName,
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
      isTemporaryClosurePending: json['isTemporaryClosurePending'] ?? json['is_temporary_closure_pending'] ?? false,
      temporaryClosureReason: json['temporaryClosureReason'] ?? json['temporary_closure_reason'],
      temporaryClosureDays: json['temporaryClosureDays'] ?? json['temporary_closure_days'],
      ownerName: json['ownerName'] ?? json['owner_name'],
    );
  }
}
