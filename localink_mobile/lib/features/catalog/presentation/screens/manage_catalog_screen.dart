import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/catalog_models.dart';
import '../providers/catalog_provider.dart';
import '../../../shared/presentation/widgets/app_button.dart';

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
  String selectedCurrency = 'INR';
  final List<Map<String, String>> currencies = [
    {'code': 'INR', 'name': 'Indian Rupee', 'flag': '🇮🇳'},
    {'code': 'USD', 'name': 'US Dollar', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound', 'flag': '🇬🇧'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'flag': '🇯🇵'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'flag': '🇦🇺'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'flag': '🇨🇦'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'flag': '🇸🇬'},
    {'code': 'AED', 'name': 'UAE Dirham', 'flag': '🇦🇪'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'flag': '🇨🇳'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'flag': '🇨🇭'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'flag': '🇭🇰'},
    {'code': 'NZD', 'name': 'New Zealand Dollar', 'flag': '🇳🇿'},
    {'code': 'SEK', 'name': 'Swedish Krona', 'flag': '🇸🇪'},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'flag': '🇳🇴'},
    {'code': 'DKK', 'name': 'Danish Krone', 'flag': '🇩🇰'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'flag': '🇲🇽'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'flag': '🇧🇷'},
    {'code': 'KRW', 'name': 'South Korean Won', 'flag': '🇰🇷'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'flag': '🇹🇷'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'flag': '🇷🇺'},
    {'code': 'ZAR', 'name': 'South African Rand', 'flag': '🇿🇦'},
    {'code': 'THB', 'name': 'Thai Baht', 'flag': '🇹🇭'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'flag': '🇮🇩'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'flag': '🇲🇾'},
    {'code': 'PHP', 'name': 'Philippine Peso', 'flag': '🇵🇭'},
    {'code': 'VND', 'name': 'Vietnamese Dong', 'flag': '🇻🇳'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'flag': '🇵🇰'},
    {'code': 'BDT', 'name': 'Bangladeshi Taka', 'flag': '🇧🇩'},
    {'code': 'LKR', 'name': 'Sri Lankan Rupee', 'flag': '🇱🇰'},
    {'code': 'NPR', 'name': 'Nepalese Rupee', 'flag': '🇳🇵'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'flag': '🇪🇬'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'flag': '🇸🇦'},
    {'code': 'QAR', 'name': 'Qatari Riyal', 'flag': '🇶🇦'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar', 'flag': '🇰🇼'},
    {'code': 'BHD', 'name': 'Bahraini Dinar', 'flag': '🇧🇭'},
    {'code': 'OMR', 'name': 'Omani Rial', 'flag': '🇴🇲'},
    {'code': 'ILS', 'name': 'Israeli Shekel', 'flag': '🇮🇱'},
    {'code': 'PLN', 'name': 'Polish Zloty', 'flag': '🇵🇱'},
    {'code': 'CZK', 'name': 'Czech Koruna', 'flag': '🇨🇿'},
    {'code': 'HUF', 'name': 'Hungarian Forint', 'flag': '🇭🇺'},
    {'code': 'RON', 'name': 'Romanian Leu', 'flag': '🇷🇴'},
    {'code': 'BGN', 'name': 'Bulgarian Lev', 'flag': '🇧🇬'},
    {'code': 'HRK', 'name': 'Croatian Kuna', 'flag': '🇭🇷'},
    {'code': 'NGN', 'name': 'Nigerian Naira', 'flag': '🇳🇬'},
    {'code': 'KES', 'name': 'Kenyan Shilling', 'flag': '🇰🇪'},
    {'code': 'GHS', 'name': 'Ghanaian Cedi', 'flag': '🇬🇭'},
    {'code': 'UGX', 'name': 'Ugandan Shilling', 'flag': '🇺🇬'},
    {'code': 'TZS', 'name': 'Tanzanian Shilling', 'flag': '🇹🇿'},
    {'code': 'ZMW', 'name': 'Zambian Kwacha', 'flag': '🇿🇲'},
    {'code': 'BWP', 'name': 'Botswanan Pula', 'flag': '🇧🇼'},
    {'code': 'NAD', 'name': 'Namibian Dollar', 'flag': '🇳🇦'},
    {'code': 'AOA', 'name': 'Angolan Kwanza', 'flag': '🇦🇴'},
    {'code': 'MZN', 'name': 'Mozambican Metical', 'flag': '🇲🇿'},
    {'code': 'COP', 'name': 'Colombian Peso', 'flag': '🇨🇴'},
    {'code': 'PEN', 'name': 'Peruvian Sol', 'flag': '🇵🇪'},
    {'code': 'CLP', 'name': 'Chilean Peso', 'flag': '🇨🇱'},
    {'code': 'ARS', 'name': 'Argentine Peso', 'flag': '🇦🇷'},
    {'code': 'UYU', 'name': 'Uruguayan Peso', 'flag': '🇺🇾'},
    {'code': 'PYG', 'name': 'Paraguayan Guarani', 'flag': '🇵🇾'},
    {'code': 'BOB', 'name': 'Bolivian Boliviano', 'flag': '🇧🇴'},
    {'code': 'CRC', 'name': 'Costa Rican Colón', 'flag': '🇨🇷'},
    {'code': 'PAB', 'name': 'Panamanian Balboa', 'flag': '🇵🇦'},
    {'code': 'DOP', 'name': 'Dominican Peso', 'flag': '🇩🇴'},
    {'code': 'JMD', 'name': 'Jamaican Dollar', 'flag': '🇯🇲'},
    {'code': 'TTD', 'name': 'Trinidad & Tobago Dollar', 'flag': '🇹🇹'},
    {'code': 'BBD', 'name': 'Barbadian Dollar', 'flag': '🇧🇧'},
    {'code': 'XCD', 'name': 'East Caribbean Dollar', 'flag': '🇪🇨'},
  ];
  
  void _showAddCatalogDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Catalog Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Category Name (e.g. Lunch)'),
                    enabled: !isSaving,
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                    enabled: !isSaving,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Category name is required';
                            });
                            return;
                          }
                          setDialogState(() {
                            isSaving = true;
                            errorMessage = null;
                          });
                          try {
                            await ref.read(catalogNotifierProvider.notifier).createCatalog(
                                  widget.businessId,
                                  titleController.text.trim(),
                                  descController.text.trim().isEmpty ? null : descController.text.trim(),
                                );
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                          } catch (e) {
                            if (dialogCtx.mounted) {
                              setDialogState(() {
                                isSaving = false;
                                final cleanMsg = e.toString().replaceFirst('Exception: ', '').trim();
                                errorMessage = cleanMsg.isNotEmpty ? cleanMsg : 'Failed to create category';
                              });
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _CatTok.primary),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
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
        bool isSaving = false;
        String? errorMessage;

        return StatefulBuilder(builder: (sheetCtx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
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
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                    enabled: !isSaving,
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    enabled: !isSaving,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: !isSaving,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCurrency,
                          decoration: const InputDecoration(labelText: 'Currency'),
                          items: currencies.map((currency) {
                            return DropdownMenuItem<String>(
                              value: currency['code'],
                              child: Row(
                                children: [
                                  Text(currency['flag']!, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(currency['code']!),
                                  const SizedBox(width: 4),
                                  Text(
                                    '- ${currency['name']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: isSaving ? null : (value) {
                            setState(() {
                              selectedCurrency = value ?? 'INR';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available?'),
                      Switch(
                        value: isAvailable,
                        onChanged: isSaving ? null : (val) => setState(() => isAvailable = val),
                        activeColor: _CatTok.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: isSaving ? null : () async {
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
                          : (item?.imageUrl?.isNotEmpty ?? false)
                              ? Image.network(
                                  DioClient.resolveUrl(item!.imageUrl)!,
                                  fit: BoxFit.cover,
                                )
                              : const Center(child: Text('Tap to add image', style: TextStyle(color: _CatTok.textMedium))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Save',
                    isLoading: isSaving,
                    onPressed: isSaving ? null : () async {
                      final priceText = priceController.text.trim();
                      if (nameController.text.trim().isEmpty) {
                        setState(() {
                          errorMessage = 'Item name is required';
                        });
                        return;
                      }
                      final price = double.tryParse(priceText) ?? 0.0;
                      if (price <= 0) {
                        setState(() {
                          errorMessage = 'Price must be a valid number greater than 0';
                        });
                        return;
                      }

                      setState(() {
                        isSaving = true;
                        errorMessage = null;
                      });

                      try {
                        if (item == null) {
                          await ref.read(catalogNotifierProvider.notifier).addCatalogItem(
                                widget.businessId,
                                catalogId,
                                nameController.text.trim(),
                                descController.text.trim(),
                                price,
                                isAvailable,
                                selectedImage,
                                selectedCurrency,
                              );
                        } else {
                          await ref.read(catalogNotifierProvider.notifier).updateCatalogItem(
                                widget.businessId,
                                item.id,
                                nameController.text.trim(),
                                descController.text.trim(),
                                price,
                                isAvailable,
                                selectedImage,
                                selectedCurrency,
                              );
                        }
                        if (sheetCtx.mounted) {
                          Navigator.pop(sheetCtx);
                        }
                      } catch (e) {
                        if (sheetCtx.mounted) {
                          setState(() {
                            isSaving = false;
                            final cleanMsg = e.toString().replaceFirst('Exception: ', '').trim();
                            errorMessage = cleanMsg.isNotEmpty ? cleanMsg : 'Failed to save catalog item';
                          });
                        }
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
                      leading: (item.imageUrl?.isNotEmpty ?? false)
                          ? Image.network(
                              DioClient.resolveUrl(item.imageUrl)!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.inventory_2_rounded, size: 40),
                      title: Text(item.name),
                      subtitle: Text('${item.price.toStringAsFixed(2)}'),
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
