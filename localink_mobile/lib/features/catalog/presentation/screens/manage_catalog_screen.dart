import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/catalog_models.dart';
import '../providers/catalog_provider.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../../core/network/dio_client.dart';

class _CatTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
}

class ManageCatalogScreen extends ConsumerStatefulWidget {
  final int businessId;
  const ManageCatalogScreen({super.key, required this.businessId});

  @override
  ConsumerState<ManageCatalogScreen> createState() => _ManageCatalogScreenState();
}

class _ManageCatalogScreenState extends ConsumerState<ManageCatalogScreen> {
  void _showAddCatalogDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Catalog Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Category Name (e.g. Lunch)'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                ref.read(catalogNotifierProvider.notifier).createCatalog(
                      widget.businessId,
                      titleController.text.trim(),
                      descController.text.trim().isEmpty ? null : descController.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref, int catalogId, {CatalogItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    bool isAvailable = item?.isAvailable ?? true;
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item == null ? 'Add Item' : 'Edit Item', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name')),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available?'),
                      Switch(
                        value: isAvailable,
                        onChanged: (val) => setState(() => isAvailable = val),
                        activeColor: _CatTok.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final xfile = await picker.pickImage(source: ImageSource.gallery);
                      if (xfile != null) {
                        setState(() {
                          selectedImage = File(xfile.path);
                        });
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: _CatTok.surface,
                      child: selectedImage != null
                          ? Image.file(selectedImage!, fit: BoxFit.cover)
                          : item?.imageUrl != null
                              ? Image.network('https://bulldog-kinsman-tutor.ngrok-free.dev/' + item!.imageUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo, color: _CatTok.textMedium),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Save',
                    onPressed: () {
                      final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                      if (nameController.text.trim().isNotEmpty && price > 0) {
                        if (item == null) {
                          ref.read(catalogNotifierProvider.notifier).addCatalogItem(
                                widget.businessId,
                                catalogId,
                                nameController.text.trim(),
                                descController.text.trim(),
                                price,
                                isAvailable,
                                selectedImage,
                              );
                        } else {
                          ref.read(catalogNotifierProvider.notifier).updateCatalogItem(
                                widget.businessId,
                                item.id,
                                nameController.text.trim(),
                                descController.text.trim(),
                                price,
                                isAvailable,
                                selectedImage,
                              );
                        }
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogsAsync = ref.watch(catalogsProvider(widget.businessId));

    return Scaffold(
      backgroundColor: _CatTok.bg,
      appBar: AppBar(
        backgroundColor: _CatTok.bg,
        title: const Text('Manage Catalog', style: TextStyle(color: _CatTok.textHigh)),
        iconTheme: const IconThemeData(color: _CatTok.textHigh),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _CatTok.primary),
            onPressed: () => _showAddCatalogDialog(context, ref),
          )
        ],
      ),
      body: catalogsAsync.when(
        data: (catalogs) {
          if (catalogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, size: 64, color: _CatTok.border),
                  const SizedBox(height: 16),
                  const Text('No catalogs yet', style: TextStyle(color: _CatTok.textMedium)),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Create First Category',
                    onPressed: () => _showAddCatalogDialog(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: catalogs.length,
            itemBuilder: (ctx, idx) {
              final catalog = catalogs[idx];
              return Card(
                margin: const EdgeInsets.all(8),
                color: _CatTok.surface,
                child: ExpansionTile(
                  title: Text(catalog.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: catalog.description != null ? Text(catalog.description!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: _CatTok.primary),
                        onPressed: () => _showAddItemDialog(context, ref, catalog.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          ref.read(catalogNotifierProvider.notifier).deleteCatalog(widget.businessId, catalog.id);
                        },
                      ),
                    ],
                  ),
                  children: catalog.items.map((item) {
                    return ListTile(
                      leading: item.imageUrl != null
                          ? Image.network('https://bulldog-kinsman-tutor.ngrok-free.dev/' + item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.fastfood, size: 40),
                      title: Text(item.name),
                      subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showAddItemDialog(context, ref, catalog.id, item: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () {
                              ref.read(catalogNotifierProvider.notifier).deleteCatalogItem(widget.businessId, item.id);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: _CatTok.primary)),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
