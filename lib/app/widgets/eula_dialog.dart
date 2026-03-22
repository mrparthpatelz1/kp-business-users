import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class EulaDialog extends StatelessWidget {
  const EulaDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: 70.h),
        child: Column(
          children: [
            Text(
              'End User License Agreement (EULA)',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _eulaText,
                  style: TextStyle(fontSize: 14.sp, height: 1.5),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _eulaText = '''
Last Updated: March 22, 2026

Welcome to the KP Business Community Platform. By using our application, you agree to the following terms and conditions.

1. ACCEPTANCE OF TERMS
By creating an account, you agree to be bound by this End User License Agreement (EULA).

2. USER-GENERATED CONTENT (UGC)
Our platform allow users to post information, text, photos, and other content. You are solely responsible for the content you post.

3. ZERO TOLERANCE POLICY FOR OBJECTIONABLE CONTENT
There is strictly ZERO TOLERANCE for objectionable content or abusive users. You agree not to post content that is:
- Defamatory, obscene, pornographic, vulgar, or offensive.
- Promoting discrimination, bigotry, racism, hatred, harassment, or harm against any individual or group.
- Violent or threatening or promotes violence or actions that are threatening to any person or entity.
- Illegal or promotes illegal activities.

4. CONTENT MODERATION AND USER CONDUCT
We reserve the right, but are not obligated, to monitor and review UGC. We may, at our sole discretion, remove any content and/or block any user account that violates these terms. 

5. REPORTING VIOLATIONS
Users can report any objectionable content or abusive behavior through the reporting tools within the app. We will take action on reported content within 24 hours.

6. TERMINATION
Failure to comply with these terms will result in immediate termination of your access to the platform without prior notice.

7. PRIVACY
Your use of the app is also governed by our Privacy Policy.

If you have any questions regarding this EULA, please contact us.
''';
}
