import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/auth/presentation/pages/login_screen.dart';
import '../../services/push_notification_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../notifications/notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isUploadingImage = false;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _birthday = '';
  String? _profileImageUrl;
  String _memberSince = '';

  bool _biometricLogin = true;
  bool _twoFactorAuth = false;

  @override
  void initState() {
    super.initState();
    _fetchHomeownerData();
  }

  int _calculateAge(String birthDateStr) {
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age >= 0 ? age : 0;
    } catch (e) {
      return 0;
    }
  }

  String _formatRegistrationDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.year}';
  }

  Future<void> _fetchHomeownerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.metadata.creationTime != null) {
          _memberSince = _formatRegistrationDate(user.metadata.creationTime);
        }

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _firstName =
                data['firstName'] ??
                data['name']?.toString().split(' ').first ??
                '';
            _lastName =
                data['lastName'] ??
                data['name']?.toString().split(' ').skip(1).join(' ') ??
                '';
            _email = data['email'] ?? user.email ?? '';
            _phone = data['phone'] ?? data['phoneNumber'] ?? '';
            _address = data['address'] ?? data['homeAddress'] ?? '';
            _birthday = data['birthday'] ?? '';
            _profileImageUrl = data['profileImageUrl'] ?? data['photoUrl'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Fallback on error
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadImage() async {
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
      final String base64Image =
          'data:image/jpeg;base64,${base64Encode(bytes)}';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profileImageUrl': base64Image,
      }, SetOptions(merge: true));

      final postsSnapshot = await FirebaseFirestore.instance
          .collection('provider_posts')
          .get();
      for (var postDoc in postsSnapshot.docs) {
        final commentsSnapshot = await postDoc.reference
            .collection('comments')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var commentDoc in commentsSnapshot.docs) {
          await commentDoc.reference.update({'profileImageUrl': base64Image});
        }
      }

      setState(() {
        _profileImageUrl = base64Image;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
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

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
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
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
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

  void _showAccountInformationDialog() {
    final firstNameController = TextEditingController(text: _firstName);
    final lastNameController = TextEditingController(text: _lastName);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);
    final addressController = TextEditingController(text: _address);
    final birthdayController = TextEditingController(text: _birthday);

    bool isEditing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
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
                  'Account Information',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                if (!isEditing)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                    tooltip: 'Edit Profile',
                    onPressed: () {
                      setDialogState(() {
                        isEditing = true;
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing
                          ? 'You can now modify your personal details below.'
                          : 'Your account details are currently locked.',
                      style: GoogleFonts.poppins(
                        color: isEditing
                            ? const Color(0xFF38BDF8)
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      'First Name',
                      firstNameController,
                      enabled: isEditing,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      'Last Name',
                      lastNameController,
                      enabled: isEditing,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      'Email Address',
                      emailController,
                      enabled: isEditing,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      'Phone Number',
                      phoneController,
                      enabled: isEditing,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      'Birthday (YYYY-MM-DD)',
                      birthdayController,
                      enabled: isEditing,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      'Home Address',
                      addressController,
                      enabled: isEditing,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (!isEditing)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      isEditing = false;
                    });
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        title: Text(
                          'Confirm Changes',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to update your profile details?',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13.5,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(color: Colors.white54),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Confirm',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                            'firstName': firstNameController.text.trim(),
                            'lastName': lastNameController.text.trim(),
                            'name':
                                '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
                            'email': emailController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'birthday': birthdayController.text.trim(),
                            'address': addressController.text.trim(),
                          });
                    }

                    setState(() {
                      _firstName = firstNameController.text.trim();
                      _lastName = lastNameController.text.trim();
                      _email = emailController.text.trim();
                      _phone = phoneController.text.trim();
                      _birthday = birthdayController.text.trim();
                      _address = addressController.text.trim();
                    });

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Account information updated successfully',
                        ),
                        backgroundColor: Color(0xFF10B981),
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
                    'Save Changes',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          );
        },
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
                      'Privacy & Security',
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
                _buildTextField(
                  'Current Password',
                  currentPassController,
                  obscure: true,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  'New Password',
                  newPassController,
                  obscure: true,
                ),
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
                            content: Text(
                              'Please fill in both password fields',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (newPassword.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'New password must be at least 6 characters',
                            ),
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
                            content: Text(
                              'Failed to update password: ${e.message}',
                            ),
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
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
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
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Use fingerprint or Face ID to log in',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11.5,
                    ),
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
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Extra security layer for your account',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11.5,
                    ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    bool enabled = true,
  }) {
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
        fillColor: enabled
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.02),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    ),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF030712),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    final int age = _calculateAge(_birthday);
    final String displayName =
        '${_firstName.isNotEmpty ? _firstName : 'Homeowner'} $_lastName'.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
      body: Stack(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ELITE TOP HEADER CARD (LUXURY STYLE) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF38BDF8,
                                      ).withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ACCOUNT MANAGEMENT',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'My Profile',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Manage your personal details & security',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- PROFILE INFO CARD ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  GestureDetector(
                                    onTap: _isUploadingImage
                                        ? null
                                        : _pickAndUploadImage,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 66,
                                        height: 66,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF0EA5E9,
                                          ).withValues(alpha: 0.2),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF38BDF8,
                                            ).withValues(alpha: 0.4),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: _isUploadingImage
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFF38BDF8),
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : (_profileImageUrl != null &&
                                                      _profileImageUrl!
                                                          .isNotEmpty
                                                  ? (_profileImageUrl!
                                                            .startsWith(
                                                              'data:image',
                                                            )
                                                        ? Image.memory(
                                                            base64Decode(
                                                              _profileImageUrl!
                                                                  .split(',')
                                                                  .last,
                                                            ),
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  _,
                                                                  _,
                                                                ) => _buildAvatarFallback(
                                                                  displayName,
                                                                ),
                                                          )
                                                        : Image.network(
                                                            _profileImageUrl!,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  _,
                                                                  _,
                                                                ) => _buildAvatarFallback(
                                                                  displayName,
                                                                ),
                                                          ))
                                                  : _buildAvatarFallback(
                                                      displayName,
                                                    )),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _isUploadingImage
                                        ? null
                                        : _pickAndUploadImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF0F172A),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      age > 0
                                          ? 'Homeowner • Age $age'
                                          : 'Homeowner',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0284C7,
                                        ).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF38BDF8,
                                          ).withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_user_rounded,
                                            color: Color(0xFF38BDF8),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Verified Account',
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF38BDF8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Member Since: ${_memberSince.isNotEmpty ? _memberSince : 'September 2026'}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Account Management',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    _buildActionTile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Account Information',
                      subtitle: 'View and edit your personal details',
                      onTap: _showAccountInformationDialog,
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Settings & Activity',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    _buildActionTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Manage alerts and reminders',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.security_outlined,
                      title: 'Privacy & Security',
                      subtitle: 'Password, biometrics, and 2FA',
                      onTap: _showSecuritySettingsModal,
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _logout(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor: Colors.redAccent.withValues(
                            alpha: 0.06,
                          ),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
