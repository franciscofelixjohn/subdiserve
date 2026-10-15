import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/auth/presentation/pages/login_screen.dart';
import '../../services/push_notification_service.dart';
import '../../services/review_service.dart';
import '../../widgets/provider_bottom_nav_bar.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  bool _isUploadingImage = false;

  bool _biometricLogin = true;
  bool _twoFactorAuth = false;

  Future<void> _pickAndUploadImage(String currentFullName) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 50,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final bytes = await pickedFile.readAsBytes();
      final String base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .set({
        'profileImageUrl': base64Image,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'profileImageUrl': base64Image,
      }, SetOptions(merge: true));

      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider profile picture updated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAppealDialog(String fullName) {
    final appealController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: Colors.redAccent.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        title: Text(
          'Appeal Account Suspension',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide your reason or explanation for review by the administrator to lift the suspension.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: appealController,
                maxLines: 4,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Type your appeal reason here...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF38BDF8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = appealController.text.trim();
              if (reason.isEmpty) return;

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('appeals').add({
                  'providerId': user.uid,
                  'providerName': fullName,
                  'reason': reason,
                  'status': 'pending',
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appeal submitted successfully to admin!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Submit Appeal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          color: const Color(0xFF38BDF8),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
        ),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await PushNotificationService.instance.clearTokenForUser(uid);
    }
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showAccountInformationDialog(Map<String, dynamic> data) {
    final fullName = data['name'] ?? data['fullName'] ?? '';
    final nameParts = fullName.split(' ');
    
    String initialFirst = nameParts.isNotEmpty ? nameParts.first : '';
    String initialLast = nameParts.length > 1 ? nameParts.last : '';
    String initialMiddle = '';
    
    if (nameParts.length > 2) {
      initialMiddle = nameParts[1];
      initialLast = nameParts.sublist(2).join(' ');
    }

    final firstNameController = TextEditingController(text: initialFirst);
    final middleInitialController = TextEditingController(text: initialMiddle.length <= 2 ? initialMiddle : '');
    final lastNameController = TextEditingController(text: initialLast);
    final expController = TextEditingController(text: data['experience'] ?? '');
    final catController = TextEditingController(text: data['service'] ?? data['serviceCategory'] ?? '');
    final rateController = TextEditingController(text: data['rates'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');
    final areaController = TextEditingController(text: data['serviceArea'] ?? '');
    final resumeController = TextEditingController(text: data['validIdUrl'] ?? data['resumeUrl'] ?? '');

    bool isEditable = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Application & Details',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              if (!isEditable)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF38BDF8), size: 20),
                  onPressed: () {
                    setDialogState(() {
                      isEditable = true;
                    });
                  },
                ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField('First Name', firstNameController, enabled: isEditable),
                  const SizedBox(height: 14),
                  _buildTextField('Middle Initial (Optional)', middleInitialController, enabled: isEditable),
                  const SizedBox(height: 14),
                  _buildTextField('Last Name', lastNameController, enabled: isEditable),
                  const SizedBox(height: 14),
                  _buildTextField('Service Category / Application', catController, enabled: isEditable),
                  const SizedBox(height: 14),
                  _buildTextField('Experience', expController, enabled: isEditable),
                  const SizedBox(height: 14),
                  _buildTextField('Service Rates', rateController, enabled: isEditable),
                  const SizedBox(height: 14),
                  _buildTextField('Resume / Valid ID Link or Filename', resumeController, enabled: isEditable),
                  const SizedBox(height: 14),
                  _buildTextField('Email Address', emailController, enabled: isEditable),
                  const SizedBox(height: 14),
                  _buildTextField('Phone Number', phoneController, enabled: isEditable),
                  const SizedBox(height: 14),
                  _buildTextField('Service Area', areaController, enabled: isEditable),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isEditable)
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final fName = firstNameController.text.trim();
                    final mInitial = middleInitialController.text.trim();
                    final lName = lastNameController.text.trim();
                    
                    final combinedName = mInitial.isNotEmpty 
                        ? '$fName ${mInitial.endsWith('.') ? mInitial : '$mInitial.'} $lName' 
                        : '$fName $lName';

                    await FirebaseFirestore.instance
                        .collection('providers')
                        .doc(user.uid)
                        .update({
                      'name': combinedName,
                      'service': catController.text.trim(),
                      'experience': expController.text.trim(),
                      'rates': rateController.text.trim(),
                      'validIdUrl': resumeController.text.trim(),
                      'email': emailController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'serviceArea': areaController.text.trim(),
                      'verificationStatus': 'pending',
                    });
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application updated & submitted for admin review!'),
                      backgroundColor: Color(0xFFF59E0B),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Save & Submit',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSecuritySettingsModal() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Security Settings',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Password',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF38BDF8),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField('Current Password', currentPassController, obscure: true),
                const SizedBox(height: 14),
                _buildTextField('New Password', newPassController, obscure: true),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      final currentPassword = currentPassController.text.trim();
                      final newPassword = newPassController.text.trim();

                      if (currentPassword.isEmpty || newPassword.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in both password fields'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (newPassword.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New password must be at least 6 characters'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && user.email != null) {
                          final credential = EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentPassword,
                          );
                          await user.reauthenticateWithCredential(credential);
                          await user.updatePassword(newPassword);

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update password: ${e.message}'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Update Password',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Biometric Login',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Use fingerprint or Face ID to log in',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11.5),
                  ),
                  value: _biometricLogin,
                  activeThumbColor: const Color(0xFF38BDF8),
                  onChanged: (val) {
                    setModalState(() => _biometricLogin = val);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Two-Factor Authentication',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Extra security layer for your account',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11.5),
                  ),
                  value: _twoFactorAuth,
                  activeThumbColor: const Color(0xFF38BDF8),
                  onChanged: (val) {
                    setModalState(() => _twoFactorAuth = val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscure = false, bool enabled = true}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      style: GoogleFonts.poppins(
        color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.7),
        fontSize: 13.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12.5,
        ),
        filled: true,
        fillColor: enabled ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFF38BDF8), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF38BDF8),
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF030712),
        body: Center(child: Text('No user logged in', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      bottomNavigationBar: const ProviderBottomNavBar(currentIndex: 4),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('providers')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Provider data not found', style: TextStyle(color: Colors.white54)),
            );
          }

          final data = snapshot.data!.data() ?? {};
          final fullName = data['name'] ?? data['fullName'] ?? 'No Name Provided';
          final categories = data['service'] ?? data['serviceCategory'] ?? 'General Service';
          final verificationStatus = (data['verificationStatus'] ?? 'pending').toString().toLowerCase();
          final profileImageUrl = data['profileImageUrl'] ?? data['photoUrl'];
          
          final bool isApproved = verificationStatus == 'approved';
          final bool isSuspended = verificationStatus == 'suspended' || verificationStatus == 'banned';

          return Stack(
            children: [
              // Ambient Glow Background
              Positioned(
                top: -100,
                left: -50,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF030712),
                      Color(0xFF0B132B),
                      Color(0xFF030712),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- ELITE TOP HEADER CARD ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0F172A),
                              Color(0xFF1E293B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                        blurRadius: 6,
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ACCOUNT MANAGEMENT',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Provider Profile',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manage your credentials & account security',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- PROFILE CARD ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0F172A),
                              Color(0xFF1E293B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: isSuspended
                                ? Colors.redAccent.withValues(alpha: 0.5)
                                : (isApproved
                                    ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                GestureDetector(
                                  onTap: _isUploadingImage ? null : () => _pickAndUploadImage(fullName),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: _isUploadingImage
                                          ? const Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF38BDF8),
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : (profileImageUrl != null && profileImageUrl.isNotEmpty
                                              ? (profileImageUrl.startsWith('data:image')
                                                  ? Image.memory(
                                                      base64Decode(profileImageUrl.split(',').last),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) => _buildAvatarFallback(fullName),
                                                    )
                                                  : Image.network(
                                                      profileImageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) => _buildAvatarFallback(fullName),
                                                    ))
                                              : _buildAvatarFallback(fullName)),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isUploadingImage ? null : () => _pickAndUploadImage(fullName),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF0F172A), width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              fullName,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              categories,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSuspended
                                        ? Colors.redAccent.withValues(alpha: 0.2)
                                        : (isApproved
                                            ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                                            : const Color(0xFFF59E0B).withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSuspended
                                          ? Colors.redAccent.withValues(alpha: 0.4)
                                          : (isApproved
                                              ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                                              : const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSuspended
                                            ? Icons.error_outline_rounded
                                            : (isApproved
                                                ? Icons.verified_user_rounded
                                                : Icons.hourglass_empty_rounded),
                                        color: isSuspended
                                            ? Colors.redAccent
                                            : (isApproved
                                                ? const Color(0xFF38BDF8)
                                                : const Color(0xFFF59E0B)),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isSuspended
                                            ? 'Account Suspended'
                                            : (isApproved ? 'Verified Provider' : 'Pending Admin Approval'),
                                        style: GoogleFonts.poppins(
                                          color: isSuspended
                                              ? Colors.redAccent
                                              : (isApproved
                                                  ? const Color(0xFF38BDF8)
                                                  : const Color(0xFFF59E0B)),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isApproved && !isSuspended)
                                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                    stream: ReviewService().streamProviderRating(user.uid),
                                    builder: (context, ratingSnapshot) {
                                      final ratingData = ratingSnapshot.data?.data();
                                      final double avgRating =
                                          ((ratingData?['averageRating'] ?? 0) as num).toDouble();
                                      final int ratingCount =
                                          (ratingData?['ratingCount'] ?? 0) as int;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFF59E0B),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              ratingCount > 0
                                                  ? '${avgRating.toStringAsFixed(1)} ($ratingCount)'
                                                  : 'No ratings',
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFFF59E0B),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            if (isSuspended) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Your account has been suspended by the administrator.',
                                            style: GoogleFonts.poppins(
                                              color: Colors.redAccent,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showAppealDialog(fullName),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(Icons.support_agent_rounded, size: 16),
                                        label: Text(
                                          'Appeal Suspension',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Application & Details',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        icon: Icons.assignment_ind_outlined,
                        title: 'Attach Resume / Service Details',
                        subtitle: 'View or edit service category, experience, and ID',
                        onTap: () => _showAccountInformationDialog(data),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Settings & Activity',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        icon: Icons.security_outlined,
                        title: 'Security Settings',
                        subtitle: 'Manage password, biometrics, and 2FA',
                        onTap: _showSecuritySettingsModal,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _logout(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor:
                                Colors.redAccent.withValues(alpha: 0.06),
                          ),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          label: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}