import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/booking_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String providerCategory;

  const CreateBookingScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.providerCategory,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService();

  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  final List<String> _availableServices = [
    'General Inspection & Assessment',
    'Repair & Maintenance Service',
    'Installation & Setup',
    'Emergency Troubleshooting',
    'Deep Cleaning & Sanitation',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0284C7),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0B132B)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0284C7),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0B132B)),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select booking date';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select booking time';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<Map<String, dynamic>> _getHomeownerData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? <String, dynamic>{};
      final name = (data['name'] ?? data['fullName'] ?? 'Homeowner').toString().trim();
      final email = (data['email'] ?? _auth.currentUser?.email ?? '').toString().trim();
      return {
        'name': name.isEmpty ? 'Homeowner' : name,
        'email': email,
      };
    } catch (_) {
      return {
        'name': 'Homeowner',
        'email': _auth.currentUser?.email ?? '',
      };
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service type'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a booking date'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a booking time'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in first'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final homeownerData = await _getHomeownerData(currentUser.uid);
      final bookingDateTime = _combineDateAndTime(_selectedDate!, _selectedTime!);

      await _bookingService.createBooking(
        homeownerId: currentUser.uid,
        homeownerName: homeownerData['name'],
        homeownerEmail: homeownerData['email'],
        providerId: widget.providerId,
        providerName: widget.providerName,
        providerCategory: widget.providerCategory,
        service: _selectedService!,
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        bookingDateTime: bookingDateTime,
        bookingDate: _formatDate(_selectedDate),
        bookingTime: _formatTime(_selectedTime),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking submitted successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: ${e.message ?? 'Booking submission failed'}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          color: const Color(0xFF38BDF8),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Book Service',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Stack(
        children: [
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SELECTED PROVIDER CARD WITH REAL-TIME PICTURE ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: widget.providerId.isNotEmpty
                                ? FirebaseFirestore.instance
                                    .collection('providers')
                                    .doc(widget.providerId)
                                    .snapshots()
                                : null,
                            builder: (context, providerSnapshot) {
                              String? profilePic;
                              if (providerSnapshot.hasData &&
                                  providerSnapshot.data != null &&
                                  providerSnapshot.data!.exists) {
                                final pData = providerSnapshot.data!.data();
                                profilePic = pData?['profileImageUrl'] ?? pData?['photoUrl'];
                              }

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                                  child: profilePic != null && profilePic.isNotEmpty
                                      ? (profilePic.startsWith('data:image')
                                          ? Image.memory(
                                              base64Decode(profilePic.split(',').last),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _buildAvatarFallback(widget.providerName),
                                            )
                                          : Image.network(
                                              profilePic,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _buildAvatarFallback(widget.providerName),
                                            ))
                                      : _buildAvatarFallback(widget.providerName),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
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
                                    const SizedBox(width: 6),
                                    Text(
                                      'SELECTED PROFESSIONAL',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF38BDF8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.providerName,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.providerCategory,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Appointment Details',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SERVICE DROPDOWN ---
                    DropdownButtonFormField<String>(
                      initialValue: _selectedService,
                      dropdownColor: const Color(0xFF0F172A),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Select Service Type',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                        ),
                      ),
                      items: _availableServices.map((String service) {
                        return DropdownMenuItem<String>(
                          value: service,
                          child: Text(
                            service,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedService = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a service type' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- ADDRESS ---
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Service Address',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        hintText: 'Enter complete subdivision address',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter service address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- DATE PICKER ---
                    InkWell(
                      onTap: _isSubmitting ? null : _pickDate,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(_selectedDate),
                              style: GoogleFonts.poppins(
                                color: _selectedDate == null
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white,
                                fontSize: 13.5,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: Color(0xFF38BDF8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- TIME PICKER ---
                    InkWell(
                      onTap: _isSubmitting ? null : _pickTime,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(_selectedTime),
                              style: GoogleFonts.poppins(
                                color: _selectedTime == null
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white,
                                fontSize: 13.5,
                              ),
                            ),
                            const Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: Color(0xFF38BDF8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- NOTES ---
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        hintText: 'Add specific instructions for provider',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- SUBMIT BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.5),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Confirm & Submit Booking',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
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