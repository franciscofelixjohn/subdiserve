import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../screens/admin/admin_dashboard_screen.dart';
import '../../../../screens/homeowner/home_screen.dart';
import '../../../../screens/provider/provider_dashboard_screen.dart';
import '../../../../services/suspension_service.dart';
import '../../../../services/push_notification_service.dart';
import 'register_screen.dart';
import 'suspended_account_screen.dart';

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // EmailJS Credentials
  final String serviceId = 'service_9slxsgs';
  final String templateId = 'template_9bezowc';
  final String publicKey = 'YAsAuzgbZHTFz6lSX';

  Future<String?> generateAndSendOtp(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 'Email address not found in our records.';
      }

      final userId = querySnapshot.docs.first.id;
      final otpCode = (100000 + Random().nextInt(900000)).toString();
      final expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5)));

      await _firestore.collection('users').doc(userId).update({
        'resetOtp': otpCode,
        'resetOtpExpiresAt': expiresAt,
      });

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'email': cleanEmail,
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
      return 'Error generating OTP: $e';
    }
  }

  Future<bool> verifyOtp(String email, String enteredOtp) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .get();

      if (querySnapshot.docs.isEmpty) return false;

      final data = querySnapshot.docs.first.data();
      final savedOtp = data['resetOtp']?.toString();
      final expiresAt = data['resetOtpExpiresAt'] as Timestamp?;

      if (savedOtp == null || expiresAt == null) return false;

      if (DateTime.now().isAfter(expiresAt.toDate())) {
        return false;
      }

      return savedOtp == enteredOtp.trim();
    } catch (e) {
      return false;
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showOtpForgotPasswordDialog(BuildContext context) {
    final dialogEmailController = TextEditingController(text: emailController.text);
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    
    bool codeSent = false;
    bool isDialogLoading = false;
    final OtpService otpService = OtpService();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0C2340),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
          ),
          title: Text(
            codeSent ? 'Enter Verification Code' : 'Forgot Password (OTP)',
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
              if (!codeSent) ...[
                Text(
                  'Enter your registered email address. We will send a 6-digit verification code to your Gmail.',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: dialogEmailController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'residence@subdiserve.com',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Enter the 6-digit code sent to your Gmail inbox and your new password.',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: otpController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, letterSpacing: 2),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '123456',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPasswordController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDialogLoading ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isDialogLoading
                  ? null
                  : () async {
                      final email = dialogEmailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Please enter your email address.')),
                        );
                        return;
                      }

                      setDialogState(() => isDialogLoading = true);

                      if (!codeSent) {
                        final error = await otpService.generateAndSendOtp(email);
                        setDialogState(() => isDialogLoading = false);

                        if (error != null) {
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                          );
                        } else {
                          setDialogState(() => codeSent = true);
                          if (!dialogContext.mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(
                                    CupertinoIcons.check_mark_circled_solid,
                                    color: CupertinoColors.activeGreen,
                                    size: 22,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Success',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Verification code sent to your Gmail inbox.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF1C1C1E),
                              behavior: SnackBarBehavior.floating,
                              elevation: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } else {
                        final enteredOtp = otpController.text.trim();
                        final newPassword = newPasswordController.text.trim();

                        if (enteredOtp.length != 6 || newPassword.length < 6) {
                          setDialogState(() => isDialogLoading = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Enter a valid 6-digit code and at least 6-character password.')),
                          );
                          return;
                        }

                        final isValid = await otpService.verifyOtp(email, enteredOtp);
                        if (!isValid) {
                          setDialogState(() => isDialogLoading = false);
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Invalid or expired OTP code.'), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }

                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                          setDialogState(() => isDialogLoading = false);
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('OTP Verified! Password reset flow completed successfully.'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isDialogLoading = false);
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
              child: isDialogLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(codeSent ? 'Verify & Reset' : 'Send Code', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleLogin() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => emailError = 'Email address is required.');
      hasError = true;
    } else {
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(email)) {
        setState(() => emailError = 'Invalid email format.');
        hasError = true;
      }
    }

    if (password.isEmpty) {
      setState(() => passwordError = 'Password is required.');
      hasError = true;
    }

    if (hasError) return;

    try {
      setState(() {
        isLoading = true;
      });

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      final uid = user!.uid;

      // Kukunin muna ang profile mula sa Firestore para masuri ang role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found.')),
        );
        setState(() => isLoading = false);
        return;
      }

      final data = userDoc.data();
      final role = (data?['role'] ?? '').toString().toLowerCase();

      // Kung HINDI admin at hindi pa verified ang email, saka lamang hihingi ng verification
      if (role != 'admin' && !user.emailVerified) {
        await user.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        
        if (!mounted) return;
        setState(() => isLoading = false);

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0C2340),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            title: Text(
              'Email Not Verified',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Please verify your email address before logging in. We have sent a verification link to your email.',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
        return;
      }

      final refreshedData =
          await SuspensionService().checkAndAutoLift(uid) ?? data;
      final accountStatus =
          (refreshedData?['status'] ?? 'Active').toString();

      if (accountStatus == 'Suspended') {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuspendedAccountScreen(
              userId: uid,
              userName: (refreshedData?['fullName'] ??
                      refreshedData?['name'] ??
                      'User')
                  .toString(),
              reason: (refreshedData?['suspensionReason'] ?? '').toString(),
              appealStatus:
                  (refreshedData?['appealStatus'] ?? 'none').toString(),
            ),
          ),
        );
        return;
      }

      if (accountStatus == 'Restricted') {
        final endTimestamp = refreshedData?['restrictionEndDate'];
        final endDate =
            endTimestamp is Timestamp ? endTimestamp.toDate() : null;
        final reason = (refreshedData?['suspensionReason'] ?? '').toString();
        final initialAppealStatus =
            (refreshedData?['appealStatus'] ?? 'none').toString();

        if (mounted) {
          final appealController = TextEditingController();
          bool showAppealForm = false;
          bool isSubmitting = false;
          String appealStatus = initialAppealStatus;

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return StatefulBuilder(
                builder: (dialogContext, setDialogState) {
                  Future<void> sendAppeal() async {
                    if (appealController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('Please explain your appeal.')),
                      );
                      return;
                    }

                    setDialogState(() => isSubmitting = true);
                    try {
                      await SuspensionService().submitAppeal(
                        userId: uid,
                        message: appealController.text,
                        accountStatusAtSubmission: 'Restricted',
                      );
                      setDialogState(() {
                        isSubmitting = false;
                        showAppealForm = false;
                        appealStatus = 'pending';
                      });
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Failed to submit: $e')),
                        );
                      }
                    }
                  }

                  if (showAppealForm) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text('Submit Appeal',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      content: TextField(
                        controller: appealController,
                        maxLines: 4,
                        autofocus: true,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'Explain why your restriction should be lifted...',
                          hintStyle:
                              GoogleFonts.poppins(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () =>
                                  setDialogState(() => showAppealForm = false),
                          child: Text('Back',
                              style:
                                  GoogleFonts.poppins(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : sendAppeal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text('Send',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600)),
                        ),
                      ],
                    );
                  }

                  return AlertDialog(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: Colors.orangeAccent.withValues(alpha: 0.3)),
                    ),
                    title: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Text('Account Restricted',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reason.isNotEmpty) ...[
                          Text('Reason: $reason',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          endDate != null
                              ? 'Your account is restricted until ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}. You can still use your account, but it will automatically become fully suspended if you don\'t appeal in time.'
                              : 'Your account is currently restricted. You can still use your account, but it will automatically become fully suspended if you don\'t appeal in time.',
                          style: GoogleFonts.poppins(
                              color: Colors.white54, fontSize: 12),
                        ),
                        if (appealStatus == 'pending') ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Your appeal has been submitted and is awaiting admin review.',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      if (appealStatus != 'pending')
                        TextButton(
                          onPressed: () =>
                              setDialogState(() => showAppealForm = true),
                          child: Text('Submit Appeal',
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF38BDF8),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black),
                        child: const Text('Continue'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }
      }

      if (accountStatus == 'Active') {
        final activationNote =
            (refreshedData?['lastActivationNote'] ?? '').toString();
        final noteAlreadySeen = refreshedData?['lastActivationNoteSeen'];

        if (activationNote.isNotEmpty && noteAlreadySeen == false) {
          if (mounted) {
            await showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text('Account Reactivated',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                content: Text(
                  'A note from the admin:\n\n"$activationNote"',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
          }
          await SuspensionService().markActivationNoteSeen(uid);
        }
      }

      await PushNotificationService.instance.saveTokenForUser(uid);

      Widget destination;

      if (role == 'homeowner') {
        destination = const HomeownerHomeScreen();
      } else if (role == 'provider') {
        destination = const ProviderDashboardScreen();
      } else if (role == 'admin') {
        destination = const AdminDashboardScreen();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user role.')),
        );
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        setState(() {
          emailError = 'Invalid email or password.';
          passwordError = 'Invalid email or password.';
        });
      } else if (e.code == 'wrong-password') {
        setState(() => passwordError = 'Incorrect password.');
      } else if (e.code == 'invalid-email') {
        setState(() => emailError = 'Invalid email address.');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
                  Color(0xFF020408),
                  Color(0xFF061021),
                  Color(0xFF0B192C),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0284C7).withValues(alpha: 0.22),
                    const Color(0xFF0284C7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.12),
                    const Color(0xFF38BDF8).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              blurRadius: 35,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SubdiServe',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exclusive Subdivision Community Portal',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 60,
                              offset: const Offset(0, 22),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Access Your Portal',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in securely to manage your services and community requests',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            CustomTextField(
                              controller: emailController,
                              labelText: 'Email Address',
                              hintText: 'residence@subdiserve.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              errorText: emailError,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: passwordController,
                              labelText: 'Password',
                              hintText: '••••••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              errorText: passwordError,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showOtpForgotPasswordDialog(context),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF0284C7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: isLoading ? 'Signing in...' : 'Sign In',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: isLoading ? () {} : handleLogin,
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account? ",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Create an account',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF0284C7),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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