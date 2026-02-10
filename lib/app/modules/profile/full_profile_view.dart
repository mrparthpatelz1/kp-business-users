import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class FullProfileView extends StatelessWidget {
  const FullProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user = Get.arguments ?? {};
    final address = user['address'];
    // Logic adapted from UserProfileContent

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

    return _buildSection(
      'Education',
      Icons.school,
      educationList
          .map(
            (edu) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Degree',
                  edu['degree_name'] ?? edu['qualification'] ?? 'N/A',
                ),
                _buildInfoRow(
                  'Institution',
                  edu['school_university'] ?? edu['institution'] ?? 'N/A',
                ),
                _buildInfoRow('Field of Study', edu['field_of_study'] ?? 'N/A'),
                _buildInfoRow(
                  'Start Year',
                  edu['start_year']?.toString() ?? 'N/A',
                ),
                _buildInfoRow(
                  'End Year',
                  edu['end_year']?.toString() ??
                      edu['passing_year']?.toString() ??
                      'N/A',
                ),
                _buildInfoRow(
                  'Grade',
                  edu['grade_percentage']?.toString() ??
                      edu['grade']?.toString() ??
                      'N/A',
                ),
                if (educationList.indexOf(edu) < educationList.length - 1)
                  Divider(height: 2.h),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildBusinessDetails(List<dynamic> businessList) {
    if (businessList.isEmpty) return const SizedBox.shrink();

    final List<Widget> widgets = [];
    for (var business in businessList) {
      widgets.addAll([
        if (business['logo'] != null)
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(
                ApiConstants.getFullUrl(business['logo']),
              ),
            ),
          ),
        SizedBox(height: 1.h),
        _buildInfoRow('Business Name', business['business_name'] ?? 'N/A'),
        _buildInfoRow(
          'Type',
          business['type']?['name'] ?? business['type_name'] ?? 'N/A',
        ),
        _buildInfoRow(
          'Category',
          business['category']?['name'] ?? business['category_name'] ?? 'N/A',
        ),
        _buildSubcategoriesInfo(business['subcategories']),
        _buildInfoRow('Description', business['description'] ?? 'N/A'),
        _buildInfoRow(
          'Year Established',
          business['year_of_establishment']?.toString() ?? 'N/A',
        ),
        _buildInfoRow('GST Number', business['gst_number'] ?? 'N/A'),
        _buildInfoRow('Website', business['website_url'] ?? 'N/A'),
        _buildInfoRow('Phone', business['business_phone'] ?? 'N/A'),
        _buildInfoRow('Email', business['business_email'] ?? 'N/A'),
        _buildInfoRow(
          'Employees',
          business['number_of_employees']?.toString() ?? 'N/A',
        ),
        if (businessList.indexOf(business) < businessList.length - 1)
          Divider(height: 2.h),
      ]);
    }

    return _buildSection('Business', Icons.business, widgets);
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
