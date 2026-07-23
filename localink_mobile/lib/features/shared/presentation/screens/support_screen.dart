import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/app_error_formatter.dart';
import '../widgets/app_feedback.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  String _selectedCategory = 'Feedback';
  int _expandedFaqIndex = -1;
  bool _isSubmitting = false;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I know if a business is verified?',
      'a': 'Every verified business displays a green badge next to its category. Verification guarantees direct ownership and direct, fee-free communication.'
    },
    {
      'q': 'What is the Llama AI Assistant?',
      'a': 'Our AI Assistant is trained to find local Sanatan shops, services, and community templates based on natural conversations and location tracking.'
    },
    {
      'q': 'Are there any platform transaction fees?',
      'a': 'No. Vocal for Sanatan is a direct-to-consumer initiative. We do not charge commissions, booking fees, or listing referral charges.'
    },
    {
      'q': 'How do I add my own business listing?',
      'a': 'Navigate to your profile from the top-right avatar, register as a Business Owner, and submit details via our Business Dashboard.'
    }
  ];

  final List<Map<String, dynamic>> _forumThreads = [
    {
      'title': 'Upcoming Ganesh Chaturthi Puja Preparations',
      'category': 'Festival Planning',
      'author': 'Pandit Rajesh Sharma',
      'replies': 24,
      'time': '2h ago'
    },
    {
      'title': 'Recommendation for local organic incense stores',
      'category': 'General Inquiry',
      'author': 'Smt. Lakshmi R.',
      'replies': 11,
      'time': '5h ago'
    },
    {
      'title': 'New Sanskrit learning centers in East Bangalore',
      'category': 'Education',
      'author': 'Acharya Dev',
      'replies': 37,
      'time': '1d ago'
    }
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      HapticFeedback.mediumImpact();
      final dio = DioClient().dio;
      
      // Post to the backend FeedbackController
      await dio.post('../feedback', data: {
        'feedback': '[$_selectedCategory] ${_feedbackController.text.trim()}',
      });

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          'Thank you! Your $_selectedCategory has been submitted successfully.',
        );
        _feedbackController.clear();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        AppFeedback.showError(
          context,
          'Failed to submit: ${AppErrorFormatter.format(e)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildForumThreads(),
                _buildFaqs(),
                _buildFeedbackForm(),
                _buildContactSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support & Community',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF1A1918),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Find answers, discuss with neighbors, or send us feedback',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF5F5C58),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumThreads() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Discussions',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF1A1918),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFFFF6600), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._forumThreads.map((thread) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAE8E3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6600).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            thread['category'],
                            style: const TextStyle(
                              color: Color(0xFFFF6600),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          thread['time'],
                          style: const TextStyle(color: Color(0xFF9F9B96), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      thread['title'],
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF1A1918),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF5F5C58)),
                        const SizedBox(width: 4),
                        Text(
                          thread['author'],
                          style: const TextStyle(color: Color(0xFF5F5C58), fontSize: 12),
                        ),
                        const Spacer(),
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF5F5C58)),
                        const SizedBox(width: 4),
                        Text(
                          '${thread['replies']} replies',
                          style: const TextStyle(color: Color(0xFF5F5C58), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFaqs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF1A1918),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_faqs.length, (index) {
            final isExpanded = _expandedFaqIndex == index;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEAE8E3)),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      _faqs[index]['q']!,
                      style: const TextStyle(
                        color: Color(0xFF1A1918),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFFFF6600),
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _expandedFaqIndex = isExpanded ? -1 : index;
                      });
                    },
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          _faqs[index]['a']!,
                          style: const TextStyle(
                            color: Color(0xFF5F5C58),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAE8E3)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit Feedback / Complaint',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF1A1918),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEAE8E3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6600), width: 1.5),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Feedback', child: Text('General Feedback')),
                  DropdownMenuItem(value: 'Complaint', child: Text('File a Complaint')),
                  DropdownMenuItem(value: 'Request', child: Text('Feature Request')),
                  DropdownMenuItem(value: 'Inquiry', child: Text('Business Listing Inquiry')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feedbackController,
                maxLines: 4,
                enabled: !_isSubmitting,
                style: const TextStyle(color: Color(0xFF1A1918), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts, report listing violations, or describe support issues in detail...',
                  hintStyle: const TextStyle(color: Color(0xFF9F9B96), fontSize: 13),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEAE8E3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6600), width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter details first';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isSubmitting ? null : _submitFeedback,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _isSubmitting ? const Color(0xFFFF9E4F) : const Color(0xFFFF6600),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isSubmitting
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFFFF6600).withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Response',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        children: [
          const Text(
            'Still need help? Reach out directly',
            style: TextStyle(color: Color(0xFF5F5C58), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildContactCard(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Live Chat',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    FocusScope.of(context).unfocus(); // Unfocus keyboard cleanly
                    AppFeedback.showInfo(context, 'Starting Live Support session...');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactCard(
                  icon: Icons.email_rounded,
                  label: 'Email Us',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    FocusScope.of(context).unfocus(); // Unfocus keyboard cleanly
                    AppFeedback.showInfo(context, 'Launching Email Composer...');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAE8E3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF6600), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A1918),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
