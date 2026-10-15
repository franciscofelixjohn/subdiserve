import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  
  final TextEditingController resumeBioController = TextEditingController();
  final TextEditingController otherCategoryController = TextEditingController();

  String selectedRole = 'Homeowner';
  String selectedCategory = 'Home Maintenance & Repairs';
  
  String? attachedFileName;
  PlatformFile? pickedFileObj; 
  
  // ✅ Bagong state para sa Provider Registration Photo
  String? attachedPhotoName;
  PlatformFile? pickedPhotoObj;

  bool isLoading = false;

  String? firstNameError;
  String? lastNameError;
  String? emailError;
  String? phoneError;
  String? passwordError;
  String? confirmPasswordError;
  String? addressError;
  String? otherCategoryError;
  String? resumeError;
  String? photoError;

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    resumeBioController.dispose();
    otherCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickResumeFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result.isNotEmpty) {
        setState(() {
          pickedFileObj = result.first;
          attachedFileName = pickedFileObj!.name;
          resumeError = null;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume attached successfully!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ✅ Function para sa pag-attach ng Provider Registration Photo
  Future<void> _pickRegistrationPhoto() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result.isNotEmpty) {
        setState(() {
          pickedPhotoObj = result.first;
          attachedPhotoName = pickedPhotoObj!.name;
          photoError = null;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration photo attached successfully!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking photo: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<String?> _sendVerificationOtp(String email, String otpCode) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': 'service_9slxsgs',
          'template_id': 'template_9bezowc',
          'user_id': 'YAsAuzgbZHTFz6lSX',
          'template_params': {
            'email': email.trim().toLowerCase(),
            'passcode': otpCode,
          },
        }),
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        return 'Failed to send email: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  void _showOtpVerificationDialog(String email, String actualOtpCode) {
    final otpInputController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Confirm Your Email',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We have sent a 6-digit verification code to $email. Please enter it below to verify your email address.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: otpInputController,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, letterSpacing: 2),
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '123456',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF0A84FF),
              borderRadius: BorderRadius.circular(10),
              onPressed: isVerifying
                  ? null
                  : () async {
                      final enteredCode = otpInputController.text.trim();
                      if (enteredCode.length != 6) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid 6-digit code.')),
                        );
                        return;
                      }

                      if (enteredCode != actualOtpCode) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Incorrect verification code.'), backgroundColor: Colors.redAccent),
                        );
                        return;
                      }

                      setDialogState(() => isVerifying = true);

                      try {
                        final firstName = firstNameController.text.trim();
                        final middleName = middleNameController.text.trim();
                        final lastName = lastNameController.text.trim();
                        final phone = phoneController.text.trim();
                        final password = passwordController.text.trim();
                        final address = addressController.text.trim();
                        final resumeBio = resumeBioController.text.trim();
                        final finalCategory = selectedCategory == 'Other' 
                            ? otherCategoryController.text.trim() 
                            : selectedCategory;

                        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        final user = userCredential.user;
                        if (user != null) {
                          await user.sendEmailVerification();
                          final String uid = user.uid;
                          final now = FieldValue.serverTimestamp();
                          final String fullName = middleName.isEmpty 
                              ? '$firstName $lastName' 
                              : '$firstName $middleName $lastName';

                          String resumeDownloadUrl = 'no_file_attached.pdf';
                          String photoDownloadUrl = 'no_photo_attached.jpg';

                          // ✅ Upload ng Resume sa Firebase Storage
                          if (selectedRole == 'Service Provider' && pickedFileObj != null) {
                            final storageRef = FirebaseStorage.instance
                                .ref()
                                .child('provider_resumes')
                                .child('${uid}_${pickedFileObj!.name}');
                            
                            final fileBytes = await pickedFileObj!.xFile.readAsBytes();
                            final uploadTask = await storageRef.putData(fileBytes);
                            resumeDownloadUrl = await uploadTask.ref.getDownloadURL();
                          }

                          // ✅ Upload ng Provider Registration Photo sa Firebase Storage
                          if (selectedRole == 'Service Provider' && pickedPhotoObj != null) {
                            final photoRef = FirebaseStorage.instance
                                .ref()
                                .child('provider_photos')
                                .child('${uid}_${pickedPhotoObj!.name}');
                            
                            final photoBytes = await pickedPhotoObj!.xFile.readAsBytes();
                            final photoUploadTask = await photoRef.putData(photoBytes);
                            photoDownloadUrl = await photoUploadTask.ref.getDownloadURL();
                          }

                          if (selectedRole == 'Homeowner') {
                            await FirebaseFirestore.instance.collection('users').doc(uid).set({
                              'firstName': firstName,
                              'middleName': middleName,
                              'lastName': lastName,
                              'fullName': fullName,
                              'email': email,
                              'phone': phone,
                              'role': selectedRole,
                              'address': address,
                              'createdAt': now,
                            });
                          } else {
                            // ✅ Dual-role support: Naka-save bilang Provider at Homeowner rin para pwede silang mag-switch o mag-book
                            await FirebaseFirestore.instance.collection('providers').doc(uid).set({
                              'firstName': firstName,
                              'middleName': middleName,
                              'lastName': lastName,
                              'name': fullName,
                              'fullName': fullName,
                              'email': email,
                              'phone': phone,
                              'service': finalCategory,
                              'serviceType': finalCategory,
                              'resumeBio': resumeBio,
                              'resumeFileUrl': resumeDownloadUrl,
                              'photoUrl': photoDownloadUrl, // ✅ Naisama ang Registration Photo URL
                              'verificationStatus': 'pending',
                              'submittedAt': now,
                              'createdAt': now, // ✅ Registration & Approval Dates tracking base sa checklist
                            });

                            await FirebaseFirestore.instance.collection('users').doc(uid).set({
                              'firstName': firstName,
                              'middleName': middleName,
                              'lastName': lastName,
                              'fullName': fullName,
                              'email': email,
                              'phone': phone,
                              'role': 'provider',
                              'address': address,
                              'createdAt': now,
                            });
                          }
                        }

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registration successful! Please check your email for verification.'),
                            backgroundColor: Color(0xFF10B981),
                            duration: Duration(seconds: 5),
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      } catch (e) {
                        setDialogState(() => isVerifying = false);
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              child: isVerifying
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Verify & Register', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleRegister() async {
    setState(() {
      firstNameError = null;
      lastNameError = null;
      emailError = null;
      phoneError = null;
      passwordError = null;
      confirmPasswordError = null;
      addressError = null;
      otherCategoryError = null;
      resumeError = null;
      photoError = null;
    });

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final address = addressController.text.trim();
    final otherCategory = otherCategoryController.text.trim();
    final resumeBio = resumeBioController.text.trim();

    bool hasError = false;

    if (firstName.isEmpty) {
      setState(() => firstNameError = 'Required');
      hasError = true;
    }

    if (lastName.isEmpty) {
      setState(() => lastNameError = 'Required');
      hasError = true;
    }

    if (address.isEmpty) {
      setState(() => addressError = 'Address is required');
      hasError = true;
    }

    if (selectedRole == 'Service Provider') {
      if (selectedCategory == 'Other' && otherCategory.isEmpty) {
        setState(() => otherCategoryError = 'Please specify');
        hasError = true;
      }
      if (resumeBio.isEmpty) {
        setState(() => resumeError = 'Required');
        hasError = true;
      }
      if (attachedFileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please attach your resume/CV document.'), backgroundColor: Colors.redAccent),
        );
        hasError = true;
      }
      if (attachedPhotoName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please attach your registration/profile photo.'), backgroundColor: Colors.redAccent),
        );
        hasError = true;
      }
    }

    if (email.isEmpty) {
      setState(() => emailError = 'Email is required');
      hasError = true;
    } else {
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(email)) {
        setState(() => emailError = 'Invalid email');
        hasError = true;
      }
    }

    if (phone.isEmpty) {
      setState(() => phoneError = 'Phone is required');
      hasError = true;
    } else if (phone.length < 10) {
      setState(() => phoneError = 'Invalid number');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => passwordError = 'Password is required');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => passwordError = 'At least 6 chars');
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() => confirmPasswordError = 'Confirm password');
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() => confirmPasswordError = 'Mismatch');
      hasError = true;
    }

    if (hasError) return;

    try {
      setState(() => isLoading = true);

      final otpCode = (100000 + Random().nextInt(900000)).toString();
      final emailErrorResult = await _sendVerificationOtp(email, otpCode);

      setState(() => isLoading = false);

      if (emailErrorResult != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(emailErrorResult), backgroundColor: Colors.redAccent),
        );
        return;
      }

      if (!mounted) return;
      _showOtpVerificationDialog(email, otpCode);

    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000000),
                  Color(0xFF0A1128),
                  Color(0xFF101F3C),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SubdiServe',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Exclusive Subdivision Community Portal',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 440),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.98),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Create Account',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Register to start using SubdiServe',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 10),
                            
                            // Names Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: CustomTextField(
                                    controller: firstNameController,
                                    labelText: 'First Name',
                                    hintText: 'First',
                                    prefixIcon: Icons.person_outline,
                                    errorText: firstNameError,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 10,
                                  child: CustomTextField(
                                    controller: middleNameController,
                                    labelText: 'Middle (Opt.)',
                                    hintText: 'Middle',
                                    prefixIcon: Icons.person_outline,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 11,
                                  child: CustomTextField(
                                    controller: lastNameController,
                                    labelText: 'Last Name',
                                    hintText: 'Last',
                                    prefixIcon: Icons.person_outline,
                                    errorText: lastNameError,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Role Selection Dropdown
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Role',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedRole,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'Homeowner', child: Text('Homeowner')),
                                          DropdownMenuItem(value: 'Service Provider', child: Text('Service Provider')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              selectedRole = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            CustomTextField(
                              controller: addressController,
                              labelText: 'Subdivision Address',
                              hintText: 'Phase, Block, Lot',
                              prefixIcon: Icons.home_outlined,
                              errorText: addressError,
                            ),

                            if (selectedRole == 'Service Provider') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'General Area',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedCategory,
                                          isExpanded: true,
                                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'Home Maintenance & Repairs', child: Text('Home Maintenance & Repairs')),
                                            DropdownMenuItem(value: 'Cleaning & Sanitization', child: Text('Cleaning & Sanitization')),
                                            DropdownMenuItem(value: 'Electrical & Power Systems', child: Text('Electrical & Power Systems')),
                                            DropdownMenuItem(value: 'Construction & Carpentry', child: Text('Construction & Carpentry')),
                                            DropdownMenuItem(value: 'Personal Care & Wellness', child: Text('Personal Care & Wellness')),
                                            DropdownMenuItem(value: 'Other', child: Text('Other (Specify)')),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                selectedCategory = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              if (selectedCategory == 'Other') ...[
                                CustomTextField(
                                  controller: otherCategoryController,
                                  labelText: 'Specify Service',
                                  hintText: 'e.g. Landscaping, Pest Control',
                                  prefixIcon: Icons.category_outlined,
                                  errorText: otherCategoryError,
                                ),
                                const SizedBox(height: 8),
                              ],

                              CustomTextField(
                                controller: resumeBioController,
                                labelText: 'Professional Bio Summary',
                                hintText: 'Brief experience...',
                                prefixIcon: Icons.description_outlined,
                                errorText: resumeError,
                              ),
                              const SizedBox(height: 8),

                              // ✅ Provider Registration Photo Picker Button
                              SizedBox(
                                width: double.infinity,
                                height: 38,
                                child: OutlinedButton.icon(
                                  onPressed: _pickRegistrationPhoto,
                                  icon: const Icon(Icons.photo_camera_rounded, size: 16),
                                  label: Text(
                                    attachedPhotoName != null ? 'Photo: $attachedPhotoName' : 'Attach Registration / ID Photo',
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: attachedPhotoName != null ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                                    side: BorderSide(
                                      color: attachedPhotoName != null ? const Color(0xFF10B981) : AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              SizedBox(
                                width: double.infinity,
                                height: 38,
                                child: OutlinedButton.icon(
                                  onPressed: _pickResumeFile,
                                  icon: const Icon(Icons.attach_file_rounded, size: 16),
                                  label: Text(
                                    attachedFileName != null ? 'Resume: $attachedFileName' : 'Attach CV / Resume (PDF / Docx)',
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: attachedFileName != null ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                                    side: BorderSide(
                                      color: attachedFileName != null ? const Color(0xFF10B981) : AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),

                            // Email at Phone Number Row
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: emailController,
                                    labelText: 'Email Address',
                                    hintText: 'name@gmail.com',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    errorText: emailError,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomTextField(
                                    controller: phoneController,
                                    labelText: 'Phone Number',
                                    hintText: '09123456789',
                                    prefixIcon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    errorText: phoneError,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Password Row
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: passwordController,
                                    labelText: 'Password',
                                    hintText: '••••••',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: true,
                                    errorText: passwordError,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomTextField(
                                    controller: confirmPasswordController,
                                    labelText: 'Confirm Password',
                                    hintText: '••••••',
                                    prefixIcon: Icons.lock_reset_outlined,
                                    obscureText: true,
                                    errorText: confirmPasswordError,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            CustomButton(
                              text: isLoading ? 'Sending Code...' : 'Register Account',
                              icon: Icons.person_add_alt_1,
                              onPressed: isLoading ? () {} : handleRegister,
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Already have an account? Login',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}