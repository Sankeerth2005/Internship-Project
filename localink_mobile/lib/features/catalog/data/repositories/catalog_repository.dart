import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/catalog_models.dart';

class CatalogRepository {
  final DioClient _dioClient;

  CatalogRepository(this._dioClient);

  Future<List<Catalog>> getCatalogs(int businessId) async {
    try {
      final response = await _dioClient.dio.get('/catalog/$businessId');
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => Catalog.fromJson(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load catalogs');
    } catch (e) {
      rethrow;
    }
  }

  Future<Catalog> createCatalog(int businessId, String title, String? description) async {
    try {
      final response = await _dioClient.dio.post('/catalog/$businessId', data: {
        'title': title,
        'description': description,
      });
      if (response.data['success'] == true) {
        return Catalog.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create catalog');
    } catch (e) {
      rethrow;
    }
  }

  Future<Catalog> updateCatalog(int catalogId, String title, String? description) async {
    try {
      final response = await _dioClient.dio.put('/catalog/$catalogId', data: {
        'title': title,
        'description': description,
      });
      if (response.data['success'] == true) {
        return Catalog.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update catalog');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCatalog(int catalogId) async {
    try {
      await _dioClient.dio.delete('/catalog/$catalogId');
    } catch (e) {
      rethrow;
    }
  }

  Future<CatalogItem> addCatalogItem(
    int catalogId,
    String name,
    String? description,
    double price,
    bool isAvailable,
    File? image,
  ) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'description': description,
        'price': price,
        'isAvailable': isAvailable,
      });

      if (image != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(image.path, filename: image.path.split('/').last),
        ));
      }

      final response = await _dioClient.dio.post('/catalog/$catalogId/items', data: formData);
      if (response.data['success'] == true) {
        return CatalogItem.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to add item');
    } catch (e) {
      rethrow;
    }
  }

  Future<CatalogItem> updateCatalogItem(
    int itemId,
    String name,
    String? description,
    double price,
    bool isAvailable,
    File? image,
  ) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'description': description,
        'price': price,
        'isAvailable': isAvailable,
      });

      if (image != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(image.path, filename: image.path.split('/').last),
        ));
      }

      final response = await _dioClient.dio.put('/catalog/items/$itemId', data: formData);
      if (response.data['success'] == true) {
        return CatalogItem.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update item');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCatalogItem(int itemId) async {
    try {
      await _dioClient.dio.delete('/catalog/items/$itemId');
    } catch (e) {
      rethrow;
    }
  }
}
