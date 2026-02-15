import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import 'profile_controller.dart';

class FullProfileView extends StatelessWidget {
  const FullProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // Try to get data from arguments first, if not available/updated, check controller
    // Actually, to support updates, we should prefer the controller's current user state
    // if we are viewing "my" profile.

    // Check if we are viewing our own profile or someone else's.
    // If arguments has 'isOwnProfile' or similar, or we can check ID.

    final Map<String, dynamic> args = Get.arguments ?? {};
    final bool isOwnProfile = args['isOwnProfile'] == true;

    // If it's own profile, listen to ProfileController
    if (isOwnProfile && Get.isRegistered<ProfileController>()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Full Profile Details')),
        body: GetX<ProfileController>(
          builder: (controller) {
            final user =
                controller.profile.value ?? controller.currentUser ?? {};
            if (user.isEmpty) return const Center(child: Text('No data'));
            final address = user['address'];
            return SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(children: [_buildFullDetails(user, address)]),
            );
          },
        ),
      );
    }

    final Map<String, dynamic> user = args;
    final address = user['address'];

    return Scaffold(
      appBar: AppBar(title: const Text('Full Profile Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(children: [_buildFullDetails(user, address)]),
      ),
    );
  }

  // Copied and adapted helpers
  Widget _buildFullDetails(Map<String, dynamic> user, dynamic address) {
    final livingAddress = address is Map
        ? address['line']
        : user['living_address'];
    final livingCity = address is Map ? address['city'] : user['living_city'];
    final livingState = address is Map
        ? address['state']
        : user['living_state'];
    final livingCountry = address is Map
        ? address['country']
        : user['living_country'];
    final livingZipcode = address is Map
        ? address['zipcode']
        : user['living_zipcode'];

    return Column(
      children: [
        _buildSection('Personal Information', Icons.person, [
          _buildInfoRow('Email', user['email'] ?? 'N/A'),
          _buildInfoRow('Phone', user['phone'] ?? 'N/A'),
          _buildInfoRow(
            'Gender',
            (user['gender'] ?? 'N/A').toString().toUpperCase(),
          ),
          _buildInfoRow(
            'Date of Birth',
            _formatDate(user['date_of_birth']?.toString()),
          ),
          _buildInfoRow('Blood Group', user['blood_group'] ?? 'N/A'),
        ]),
        _buildSection('Current Address', Icons.home, [
          _buildInfoRow('Address', livingAddress ?? 'N/A'),
          _buildInfoRow('City', livingCity ?? 'N/A'),
          _buildInfoRow('State', livingState ?? 'N/A'),
          _buildInfoRow('Country', livingCountry ?? 'N/A'),
          _buildInfoRow('Zipcode', livingZipcode ?? 'N/A'),
        ]),
        _buildUserTypeDetails(user),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            Divider(height: 2.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35.w,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeDetails(Map<String, dynamic> user) {
    final userType = user['user_type']?.toString().toLowerCase();
    List<Widget> children = [];

    if (userType == 'business') {
      children.add(_buildBusinessDetails(user['businesses'] ?? []));
    } else if (userType == 'job') {
      children.add(_buildJobDetails(user['job']));
    }

    if (user['education'] != null && (user['education'] as List).isNotEmpty) {
      if (children.isNotEmpty) children.add(SizedBox(height: 2.h));
      children.add(_buildEducationDetails(user['education']));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildEducationDetails(List<dynamic> educationList) {
    if (educationList.isEmpty) return const SizedBox.shrink();

    // Debug print to see what we get
    // print('FullProfileView Education: $educationList');

    return _buildSection(
      'Education',
      Icons.school,
      educationList.map((edu) {
        final educationType = (edu['education_type'] ?? 'school')
            .toString()
            .toLowerCase();
        final isCollege = educationType == 'college';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              isCollege ? 'Degree' : 'Class/Standard',
              edu['degree_name'] ?? edu['qualification'] ?? 'N/A',
            ),
            _buildInfoRow(
              isCollege ? 'College/University' : 'School',
              edu['school_university'] ?? edu['institution'] ?? 'N/A',
            ),
            // Only show field of study/stream for college
            if (isCollege)
              _buildInfoRow('Stream/Branch', edu['field_of_study'] ?? 'N/A'),

            _buildInfoRow('Start Year', edu['start_year']?.toString() ?? 'N/A'),

            // Handle currently studying logic if needed, but for now just show end/passing year
            _buildInfoRow(
              (edu['is_currently_studying'] == true ||
                      edu['is_currently_studying'] == 1)
                  ? 'Expected End Year'
                  : 'Passing Year',
              edu['end_year']?.toString() ??
                  edu['passing_year']?.toString() ??
                  'N/A',
            ),
            _buildInfoRow(
              'Grade/Percentage',
              edu['grade_percentage']?.toString() ??
                  edu['grade']?.toString() ??
                  'N/A',
            ),
            if (educationList.indexOf(edu) < educationList.length - 1)
              Divider(height: 2.h),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBusinessDetails(List<dynamic> businessList) {
    if (businessList.isEmpty) return const SizedBox.shrink();

    return Column(
      children: businessList.where((b) => b != null).map((business) {
        final List<Widget> details = [];

        // Logo
        if (business['logo'] != null) {
          details.add(
            Center(
              child: Container(
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ApiConstants.getFullUrl(business['logo']),
                    height: 15.h,
                    width: 15.h,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Add all details
        details.addAll([
          _buildInfoRow(
            'Type',
            business['type']?['name'] ?? business['type_name'] ?? 'N/A',
          ),
          _buildInfoRow(
            'Category',
            business['category']?['name'] ?? business['category_name'] ?? 'N/A',
          ),
          _buildSubcategoriesInfo(business['subcategories']),
          if (business['description'] != null &&
              business['description'].toString().isNotEmpty)
            _buildInfoRow('Description', business['description']),
          _buildInfoRow(
            'Address',
            business['address'] ?? business['business_address'] ?? 'N/A',
          ),
          _buildInfoRow(
            'Year Established',
            business['year_of_establishment']?.toString() ?? 'N/A',
          ),
          if (business['gst_number'] != null)
            _buildInfoRow('GST Number', business['gst_number']),
          if (business['website_url'] != null)
            _buildInfoRow('Website', business['website_url']),
          if (business['business_phone'] != null)
            _buildInfoRow('Phone', business['business_phone']),
          if (business['business_email'] != null)
            _buildInfoRow('Email', business['business_email']),
          if (business['number_of_employees'] != null)
            _buildInfoRow(
              'Employees',
              business['number_of_employees']?.toString() ?? 'N/A',
            ),
        ]);

        return _buildSection(
          business['business_name'] ?? 'Business',
          Icons.store,
          details,
        );
      }).toList(),
    );
  }

  Widget _buildSubcategoriesInfo(dynamic subcategories) {
    if (subcategories == null) return _buildInfoRow('Subcategories', 'N/A');

    List subs = [];
    if (subcategories is List) {
      subs = subcategories;
    } else if (subcategories is Map) {
      subs = [subcategories];
    }

    if (subs.isEmpty) return _buildInfoRow('Subcategories', 'N/A');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35.w,
            child: Text(
              'Subcategories',
              style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: subs
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s['name'] ?? s['subcategory_name'] ?? '',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetails(Map<String, dynamic>? job) {
    if (job == null) return const SizedBox.shrink();

    return _buildSection('Job', Icons.work, [
      _buildInfoRow('Company', job['company_name'] ?? 'N/A'),
      _buildInfoRow('Designation', job['designation'] ?? 'N/A'),
      _buildInfoRow('Department', job['department'] ?? 'N/A'),
      _buildInfoRow(
        'Type',
        job['type']?['name'] ?? job['job_type_name'] ?? 'N/A',
      ),
      _buildInfoRow(
        'Category',
        job['category']?['name'] ?? job['category_name'] ?? 'N/A',
      ),
      _buildSubcategoriesInfo(job['subcategories']),
      _buildInfoRow(
        'Experience',
        '${job['years_of_experience'] ?? 'N/A'} years',
      ),
      _buildInfoRow(
        'Joining Date',
        _formatDate(job['date_of_joining']?.toString()),
      ),
      _buildInfoRow('Current Job', job['is_current'] == true ? 'Yes' : 'No'),
    ]);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
