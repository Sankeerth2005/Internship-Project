import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../../core/network/signalr_service.dart';
import '../../../../core/network/dio_client.dart';

class BusinessDashboardScreen extends ConsumerWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myBusinessesAsync = ref.watch(myBusinessesProvider);
    final authState = ref.watch(authProvider);

    if (authState is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SignalRService().connect(authState.userId, authState.userType, context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'Business Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFFF7A00)),
            onPressed: () => context.push('/owner-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF7A00)),
            onPressed: () => ref.read(myBusinessesProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              if (authState is AuthAuthenticated) {
                SignalRService().disconnect(authState.userId);
              }
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: myBusinessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.storefront, color: Color(0xFFFF7A00), size: 50),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Businesses Registered Yet',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Register your business to start displaying it to local users.',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Register Business', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/register-business'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: businesses.length,
            itemBuilder: (context, index) {
              return _buildDashboardCard(context, ref, businesses[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF7A00),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => context.push('/register-business'),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, WidgetRef ref, BusinessDto business) {
    // Determine status color
    final isApproved = business.status?.toLowerCase() == 'approved';
    Color statusColor = isApproved ? Colors.green : Colors.amber;
    var statusText = business.status ?? 'Pending';

    if (business.status?.toLowerCase() == 'deletionrequested') {
      statusColor = Colors.redAccent;
      statusText = 'Deletion Pending';
    } else if (business.isTemporarilyClosed) {
      statusColor = Colors.redAccent;
      statusText = 'Temp Closed';
    } else if (business.temporaryClosureStatus?.toLowerCase() == 'pending') {
      statusColor = Colors.orangeAccent;
      statusText = 'Closure Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Business Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: business.photos.isNotEmpty
                  ? Image.network(
                      '${Uri.parse(DioClient().dio.options.baseUrl).origin}${business.photos.first}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.store,
                        color: Color(0xFFFF7A00),
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.store,
                      color: Color(0xFFFF7A00),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 15),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        business.businessName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  business.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFFF7A00), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${business.address}, ${business.city}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.analytics_outlined, size: 14),
                      label: const Text('Analytics', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.push('/owner-analytics/${business.businessId}/${Uri.encodeComponent(business.businessName)}'),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.visibility, size: 14),
                      label: const Text('View', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.push('/business-detail/${business.businessId}'),
                    ),
                    if (business.status?.toLowerCase() != 'deletionrequested') ...[
                      if (isApproved && !business.isTemporarilyClosed && business.temporaryClosureStatus?.toLowerCase() != 'pending')
                        TextButton.icon(
                          icon: const Icon(Icons.timer_off_outlined, size: 14, color: Colors.orangeAccent),
                          label: const Text('Temp Close', style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showTemporaryClosureDialog(context, ref, business),
                        ),
                      if (business.isTemporarilyClosed || business.temporaryClosureStatus?.toLowerCase() == 'pending')
                        TextButton.icon(
                          icon: const Icon(Icons.play_circle_outline, size: 14, color: Colors.green),
                          label: const Text('Reopen', style: TextStyle(fontSize: 12, color: Colors.green)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _handleCancelTemporaryClosure(context, ref, business),
                        ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_forever_outlined, size: 14, color: Colors.redAccent),
                        label: const Text('Delete permanently', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showDeletePermanentlyDialog(context, ref, business),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit'),
                        onPressed: () => context.push('/register-business', extra: business),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTemporaryClosureDialog(BuildContext context, WidgetRef ref, BusinessDto business) async {
    final reasonController = TextEditingController();
    final daysController = TextEditingController(text: '7');
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Request Temporary Closure', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Specify the reason and duration in days for temporarily closing your business. This will be sent to the admin for approval.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 15),
              const Text('Closure Reason *', style: TextStyle(color: Color(0xFFFF7A00), fontSize: 12)),
              const SizedBox(height: 6),
              TextFormField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g., Renovation, personal emergency...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 15),
              const Text('Duration (in days) *', style: TextStyle(color: Color(0xFFFF7A00), fontSize: 12)),
              const SizedBox(height: 6),
              TextFormField(
                controller: daysController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 7',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Duration is required';
                  final val = int.tryParse(v);
                  if (val == null || val <= 0) return 'Enter a valid positive number of days';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
      );

      try {
        final repo = ref.read(businessRepositoryProvider);
        final success = await repo.requestTemporaryClosure(
          business.businessId,
          reasonController.text.trim(),
          int.parse(daysController.text.trim()),
        );

        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Temporary closure request submitted successfully for approval!'),
                backgroundColor: Colors.green,
              ),
            );
            ref.read(myBusinessesProvider.notifier).refresh();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to submit request. Please try again.'),
                backgroundColor: Color(0xFFFF4D4F),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting request: $e'), backgroundColor: const Color(0xFFFF4D4F)),
          );
        }
      }
    }
  }

  Future<void> _handleCancelTemporaryClosure(BuildContext context, WidgetRef ref, BusinessDto business) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Cancel Temporary Closure', style: TextStyle(color: Colors.white)),
        content: Text(
          business.temporaryClosureStatus?.toLowerCase() == 'pending'
              ? 'Are you sure you want to cancel your pending temporary closure request?'
              : 'Are you sure you want to reopen your business now?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Reopen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
      );

      try {
        final repo = ref.read(businessRepositoryProvider);
        final success = await repo.cancelTemporaryClosure(business.businessId);

        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Business reopened successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            ref.read(myBusinessesProvider.notifier).refresh();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to reopen business. Please try again.'),
                backgroundColor: Color(0xFFFF4D4F),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error reopening business: $e'), backgroundColor: const Color(0xFFFF4D4F)),
          );
        }
      }
    }
  }

  Future<void> _showDeletePermanentlyDialog(BuildContext context, WidgetRef ref, BusinessDto business) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Business Permanently', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please specify the reason for permanently deleting this business. This will be sent to the admin for approval. Once approved, the business will be permanently deleted from the database.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reason for permanent deletion...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Request Deletion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00))),
      );

      try {
        final repo = ref.read(businessRepositoryProvider);
        final success = await repo.requestDeletion(
          business.businessId,
          reasonController.text.trim(),
        );

        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Deletion request submitted successfully.'),
                backgroundColor: Colors.green,
              ),
            );
            ref.read(myBusinessesProvider.notifier).refresh();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to submit deletion request. Please try again.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}
