import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/features/business/data/models/business_models.dart';
import 'package:localink_mobile/features/share/utils/business_share_helper.dart';

void main() {
  test('buildSingleBusinessMessage includes dynamic fields', () {
    final business = BusinessDto(
      businessId: 1,
      businessName: 'Test Shop',
      description: 'Desc',
      categoryName: 'Restaurant',
      categoryId: 1,
      subcategoryId: 1,
      phoneNumber: '',
      phoneCode: '',
      email: '',
      website: '',
      address: '',
      city: 'Mumbai',
      state: 'MH',
      country: 'IN',
      pincode: '',
      hours: const [],
      photos: const [],
      averageRating: 0,
      reviewCount: 0,
    );

    final message = BusinessShareHelper.buildSingleBusinessMessage(
      business: business,
      shareUrl: 'https://vocalforsanatan.com/share/business/ABC',
    );

    expect(message, contains('Test Shop'));
    expect(message, contains('Restaurant'));
    expect(message, contains('Mumbai'));
    expect(message, contains('https://vocalforsanatan.com/share/business/ABC'));
  });

  test('buildCollectionMessage uses title and note', () {
    final message = BusinessShareHelper.buildCollectionMessage(
      shareUrl: 'https://example.com/share/collection/X',
      title: 'Best picks',
      note: 'Try these!',
    );
    expect(message, contains('Best picks'));
    expect(message, contains('Try these!'));
    expect(message, contains('https://example.com/share/collection/X'));
  });
}
