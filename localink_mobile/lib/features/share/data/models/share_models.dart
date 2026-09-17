import '../../../business/data/models/business_models.dart';

class ShareCreatedResult {
  final String publicToken;
  final String shareKind;
  final String shareUrl;
  final int itemCount;

  ShareCreatedResult({
    required this.publicToken,
    required this.shareKind,
    required this.shareUrl,
    required this.itemCount,
  });

  factory ShareCreatedResult.fromJson(Map<String, dynamic> json) {
    return ShareCreatedResult(
      publicToken: json['publicToken']?.toString() ?? '',
      shareKind: json['shareKind']?.toString() ?? 'collection',
      shareUrl: json['shareUrl']?.toString() ?? '',
      itemCount: json['itemCount'] is int
          ? json['itemCount'] as int
          : int.tryParse(json['itemCount']?.toString() ?? '') ?? 0,
    );
  }
}

class SharedBusinessItem {
  final int businessId;
  final int position;
  final bool isAvailable;
  final String? unavailableReason;
  final BusinessDto? business;

  SharedBusinessItem({
    required this.businessId,
    required this.position,
    required this.isAvailable,
    this.unavailableReason,
    this.business,
  });

  factory SharedBusinessItem.fromJson(Map<String, dynamic> json) {
    BusinessDto? business;
    final raw = json['business'];
    if (raw is Map) {
      business = BusinessDto.fromJson(Map<String, dynamic>.from(raw));
    }
    return SharedBusinessItem(
      businessId: json['businessId'] is int
          ? json['businessId'] as int
          : int.tryParse(json['businessId']?.toString() ?? '') ?? 0,
      position: json['position'] is int
          ? json['position'] as int
          : int.tryParse(json['position']?.toString() ?? '') ?? 0,
      isAvailable: json['isAvailable'] == true,
      unavailableReason: json['unavailableReason']?.toString(),
      business: business,
    );
  }
}

class BusinessShareView {
  final String publicToken;
  final String shareKind;
  final String title;
  final String? note;
  final String? sharedByDisplayName;
  final DateTime? createdAt;
  final List<SharedBusinessItem> items;

  BusinessShareView({
    required this.publicToken,
    required this.shareKind,
    required this.title,
    this.note,
    this.sharedByDisplayName,
    this.createdAt,
    required this.items,
  });

  factory BusinessShareView.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = <SharedBusinessItem>[];
    if (itemsRaw is List) {
      for (final e in itemsRaw) {
        if (e is Map) {
          items.add(
            SharedBusinessItem.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    DateTime? createdAt;
    final ca = json['createdAt'];
    if (ca != null) {
      createdAt = DateTime.tryParse(ca.toString());
    }
    return BusinessShareView(
      publicToken: json['publicToken']?.toString() ?? '',
      shareKind: json['shareKind']?.toString() ?? 'collection',
      title: json['title']?.toString() ?? 'Businesses shared with you',
      note: json['note']?.toString(),
      sharedByDisplayName: json['sharedByDisplayName']?.toString(),
      createdAt: createdAt,
      items: items,
    );
  }
}
