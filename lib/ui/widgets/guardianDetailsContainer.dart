import 'dart:io';

import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/guardianPhotoCubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/guardian.dart';
import 'package:eschool/ui/widgets/customUserProfileImageWidget.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

DateTime? _parseApiDob(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  final raw = s.trim();
  try {
    return DateFormat('yyyy-MM-dd').parseStrict(raw);
  } catch (_) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}

String displayIndo(DateTime d) =>
    DateFormat('d MMMM yyyy', 'id_ID').format(d).toLowerCase();

String apiYmd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

// ================== Helper Gender ===================
String genderApiToUiTitle(String? api) {
  final s = (api ?? '').trim().toLowerCase();
  if (s == 'male') return 'Laki - Laki';
  if (s == 'female') return 'Perempuan';
  return '';
}

String? genderAnyToApi(String? any) {
  final s = (any ?? '').trim().toLowerCase();
  if (s == 'male' || s == 'l' || s == 'laki-laki' || s == 'laki laki') {
    return 'male';
  }
  if (s == 'female' || s == 'p' || s == 'perempuan') {
    return 'female';
  }
  return null;
}

class GuardianDetailsContainer extends StatefulWidget {
  final Guardian guardian;
  const GuardianDetailsContainer({
    Key? key,
    required this.guardian,
  }) : super(key: key);

  @override
  State<GuardianDetailsContainer> createState() =>
      _GuardianDetailsContainerState();
}

class _GuardianDetailsContainerState extends State<GuardianDetailsContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Guardian _guardian;
  BuildContext? _lctx;
  final Color primaryColor = const Color(0xFFE53935);
  final Color secondaryColor = const Color(0xFFEF5350);
  final Color textColor = const Color(0xFF212121);
  final Color containerColor = Colors.white;

  String? _currentImageUrl;
  final ImagePicker _picker = ImagePicker();
  XFile? _pendingFile;
  final _firstNameC = TextEditingController();
  final _lastNameC = TextEditingController();
  final _genderC = TextEditingController();
  final _dobC = TextEditingController();
  final _mobileC = TextEditingController();
  final _currentAddressC = TextEditingController();
  final _permanentAddressC = TextEditingController();
  final _occupationC = TextEditingController();

  final _firstNameFN = FocusNode();
  final _lastNameFN = FocusNode();
  final _genderFN = FocusNode();
  final _dobFN = FocusNode();
  final _mobileFN = FocusNode();
  final _currentAddressFN = FocusNode();
  final _permanentAddressFN = FocusNode();
  final _occupationFN = FocusNode();

  DateTime? _selectedDob;
  String? _selectedGenderApi;

  void _attachFocusListeners() {
    for (final fn in [
      _firstNameFN,
      _lastNameFN,
      _genderFN,
      _dobFN,
      _mobileFN,
      _currentAddressFN,
      _permanentAddressFN,
      _occupationFN,
    ]) {
      fn.addListener(() => setState(() {}));
    }
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting('id_ID', null).then((_) {
      if (!mounted) return;
      if (_selectedDob != null) {
        setState(() => _dobC.text = displayIndo(_selectedDob!));
      }
    });

    _guardian = widget.guardian;
    _currentImageUrl = _guardian.image;

    _firstNameC.text = _guardian.firstName ?? '';
    _lastNameC.text = _guardian.lastName ?? '';
    _genderC.text = _guardian.gender ?? '';
    _mobileC.text = _guardian.mobile ?? '';
    _currentAddressC.text = _guardian.currentAddress ?? '';
    _permanentAddressC.text = _guardian.permanentAddress ?? '';
    _occupationC.text = _guardian.occupation ?? '';

    _selectedDob = _parseApiDob(_guardian.dob);
    _dobC.text = _selectedDob != null ? displayIndo(_selectedDob!) : '';

    _selectedGenderApi = genderAnyToApi(_guardian.gender);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
    _attachFocusListeners();
  }

  @override
  void dispose() {
    _animationController.dispose();

    _firstNameC.dispose();
    _lastNameC.dispose();
    _genderC.dispose();
    _dobC.dispose();
    _mobileC.dispose();
    _currentAddressC.dispose();
    _permanentAddressC.dispose();
    _occupationC.dispose();

    _firstNameFN.dispose();
    _lastNameFN.dispose();
    _genderFN.dispose();
    _dobFN.dispose();
    _mobileFN.dispose();
    _currentAddressFN.dispose();
    _permanentAddressFN.dispose();
    _occupationFN.dispose();

    super.dispose();
  }

  String _withCacheBuster(String url) {
    if (url.isEmpty) return url;
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  void _onChangeProfile() {
    final photoCubit = context.read<GuardianPhotoCubit>();
    showModalBottomSheet(
      context: _lctx ?? context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _buildQuickPhotoSheet(photoCubit),
    );
  }

  Future<void> _pickAndUpload(
      ImageSource source, GuardianPhotoCubit cubit) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (file == null) return;

      cubit.updateGuardianPhoto(
        guardian: widget.guardian,
        file: file,
      );

      ScaffoldMessenger.of(_lctx ?? context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mengunggah foto…',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700]!,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 30),
          elevation: 6,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(_lctx ?? context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gagal memilih gambar: $e',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 4),
          elevation: 6,
        ),
      );
    }
  }

  void _onEditFullProfile() {
    final photoCubit = context.read<GuardianPhotoCubit>();
    final formKey = GlobalKey<FormState>();
    const double _kPinnedHeaderHeight = 160;

    showModalBottomSheet(
      context: _lctx ?? context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> _pickLocal() async {
              try {
                final XFile? f = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1600,
                  maxHeight: 1600,
                  imageQuality: 88,
                );
                if (f == null) return;
                setModalState(() => _pendingFile = f);
              } catch (e) {
                ScaffoldMessenger.of(_lctx ?? context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gagal memilih gambar: $e',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFD32F2F),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    duration: const Duration(seconds: 4),
                    elevation: 6,
                  ),
                );
              }
            }

            Widget _imagePreview() {
              if (_pendingFile != null) {
                return CircleAvatar(
                  radius: 44,
                  backgroundImage: FileImage(File(_pendingFile!.path)),
                );
              }
              return CircleAvatar(
                radius: 44,
                backgroundColor: Colors.grey.shade200,
                child: ClipOval(
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: CustomUserProfileImageWidget(
                      profileUrl: _currentImageUrl ?? '',
                    ),
                  ),
                ),
              );
            }

            Future<void> _save() async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final updatedGuardian = widget.guardian.copyWith(
                firstName: _firstNameC.text.trim(),
                lastName: _lastNameC.text.trim(),
                gender: _selectedGenderApi,
                dob: _selectedDob != null ? apiYmd(_selectedDob!) : null,
                mobile: _mobileC.text.trim(),
                currentAddress: _currentAddressC.text.trim(),
                permanentAddress: _permanentAddressC.text.trim(),
                occupation: _occupationC.text.trim(),
              );

              Navigator.pop(ctx);

              photoCubit.updateGuardianPhoto(
                  guardian: updatedGuardian, file: _pendingFile);

              ScaffoldMessenger.of(_lctx ?? context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Menyimpan perubahan…',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange[700]!,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  duration: const Duration(seconds: 30),
                  elevation: 6,
                ),
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.86,
              minChildSize: 0.5,
              maxChildSize: 0.96,
              expand: false,
              builder: (context, scrollController) {
                // ⬇️ Tambahan: padding dinamis + transisi halus saat keyboard muncul
                final kb = MediaQuery.of(context).viewInsets.bottom;
                const double kStickyReserve = 90; // ruang untuk sticky bar
                final double bottomPad = (kb > 0 ? kb : kStickyReserve);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _PinnedHeader(
                              height: _kPinnedHeaderHeight,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(28)),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Container(
                                      width: 40,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            primaryColor,
                                            secondaryColor
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                primaryColor.withOpacity(0.25),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Stack(
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              _imagePreview(),
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: InkWell(
                                                  onTap: _pickLocal,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  0.15),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                        Icons
                                                            .camera_alt_outlined,
                                                        size: 18,
                                                        color: primaryColor),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Edit Profil',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: _emailBadge(
                                                        email: _guardian.email,
                                                        onDarkBg: true,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
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

                          // === FORM FIELDS === (dengan AnimatedPadding)
                          SliverToBoxAdapter(
                            child: AnimatedPadding(
                              duration:
                                  const Duration(milliseconds: 220), // halus
                              curve: Curves.easeOutCubic,
                              padding:
                                  EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                              child: Form(
                                key: formKey,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildElegantTextField(
                                            controller: _firstNameC,
                                            focusNode: _firstNameFN,
                                            isFocused: _firstNameFN.hasFocus,
                                            labelText: 'Nama Depan',
                                            hintText: 'Nama depan',
                                            icon: Icons.badge_outlined,
                                            slideAnimation: _stagger(0),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildElegantTextField(
                                            controller: _lastNameC,
                                            focusNode: _lastNameFN,
                                            isFocused: _lastNameFN.hasFocus,
                                            labelText: 'Nama Belakang',
                                            hintText: 'Nama belakang',
                                            icon: Icons.badge,
                                            slideAnimation: _stagger(1),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // ===== GENDER DROPDOWN =====
                                    _buildElegantDropdown<String>(
                                      labelText: 'Jenis Kelamin',
                                      icon: Icons.wc_outlined,
                                      focusNode: _genderFN,
                                      isFocused: _genderFN.hasFocus,
                                      slideAnimation: _stagger(2),
                                      value: _selectedGenderApi,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'male',
                                          child: Text('Laki - Laki'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'female',
                                          child: Text('Perempuan'),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        setModalState(
                                            () => _selectedGenderApi = val);
                                      },
                                      hintText: 'Pilih jenis kelamin',
                                    ),

                                    // ===== DOB =====
                                    _buildElegantTextField(
                                      controller: _dobC,
                                      focusNode: _dobFN,
                                      isFocused: _dobFN.hasFocus,
                                      labelText: 'Tanggal Lahir',
                                      hintText: '',
                                      icon: Icons.event_outlined,
                                      slideAnimation: _stagger(3),
                                      readOnly: true,
                                      onTap: _pickDob,
                                      suffixWidget: IconButton(
                                        icon: const Icon(
                                            Icons.calendar_today_outlined),
                                        onPressed: _pickDob,
                                        tooltip: 'Pilih tanggal',
                                      ),
                                    ),

                                    _buildElegantTextField(
                                      controller: _mobileC,
                                      focusNode: _mobileFN,
                                      isFocused: _mobileFN.hasFocus,
                                      labelText: 'No. HP',
                                      hintText: 'contoh: 0812xxxxxxx',
                                      icon: Icons.phone_outlined,
                                      slideAnimation: _stagger(4),
                                      keyboardType: TextInputType.phone,
                                    ),
                                    _buildElegantTextField(
                                      controller: _currentAddressC,
                                      focusNode: _currentAddressFN,
                                      isFocused: _currentAddressFN.hasFocus,
                                      labelText: 'Alamat Saat Ini',
                                      hintText:
                                          'Jalan, RT/RW, Kel/Desa, Kec, Kota/Kab',
                                      icon: Icons.location_on_outlined,
                                      slideAnimation: _stagger(5),
                                    ),
                                    _buildElegantTextField(
                                      controller: _permanentAddressC,
                                      focusNode: _permanentAddressFN,
                                      isFocused: _permanentAddressFN.hasFocus,
                                      labelText: 'Alamat Permanen',
                                      hintText:
                                          'Jalan, RT/RW, Kel/Desa, Kec, Kota/Kab',
                                      icon: Icons.home_outlined,
                                      slideAnimation: _stagger(6),
                                    ),
                                    _buildElegantTextField(
                                      controller: _occupationC,
                                      focusNode: _occupationFN,
                                      isFocused: _occupationFN.hasFocus,
                                      labelText: 'Pekerjaan',
                                      hintText:
                                          'contoh: Wiraswasta, Karyawan, dll.',
                                      icon: Icons.work_outline,
                                      slideAnimation: _stagger(7),
                                    ),

                                    // ⛔ SizedBox(height: 90) dihapus — diganti bottomPad
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // STICKY SAVE BAR (tetap seperti semula)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 12,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _save,
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Profil Lengkap'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Map field API — SESUAIKAN key dengan backend
  Map<String, String> _guardianFieldsFrom(Guardian g) {
    final m = <String, String>{
      'first_name': g.firstName ?? '',
      'last_name': g.lastName ?? '',
      'gender': g.gender ?? '',
      'dob': g.dob ?? '',
      'mobile': g.mobile ?? '',
      'current_address': g.currentAddress ?? '',
      'permanent_address': g.permanentAddress ?? '',
      'occupation': g.occupation ?? '',
    };
    m.removeWhere((k, v) => v.isEmpty);
    return m;
  }

  // ====== Date Picker (DOB) ======
  Future<void> _pickDob() async {
    final DateTime initial =
        _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 18));

    final picked = await showDatePicker(
      context: _lctx ?? context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      builder: (ctx, child) {
        final base = Theme.of(ctx);
        const textCol = Color(0xFF212121);

        return Theme(
          data: base.copyWith(
            datePickerTheme: base.datePickerTheme.copyWith(
              headerForegroundColor: textCol,
              headerHeadlineStyle:
                  base.textTheme.headlineMedium?.copyWith(color: textCol),
              headerHelpStyle:
                  base.textTheme.labelMedium?.copyWith(color: textCol),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected))
                  return Colors.white;
                return null;
              }),
            ),
            colorScheme: base.colorScheme.copyWith(
              primary: primaryColor,
              onPrimary: textCol,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobC.text = displayIndo(picked);
      });
    }
  }

  // ====== Animasi stagger per field ======
  Animation<Offset> _stagger(int index,
      {double start = 0.05, double gap = 0.08}) {
    final begin = (start + index * gap).clamp(0.0, 1.0);
    return Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(begin, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Color get _primaryRed => primaryColor;

  // ====== Elegant TextField ======
  Widget _buildElegantTextField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    bool obscureText = false,
    required IconData icon,
    required Animation<Offset> slideAnimation,
    Widget? suffixWidget,
    required bool isFocused,
    required FocusNode focusNode,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    final Color darkTextColor = const Color(0xFF303030);

    return SlideTransition(
      position: slideAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                      color: _primaryRed.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
          border: Border.all(
              color: isFocused ? _primaryRed : Colors.grey.shade200,
              width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // label
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10),
              child: Text(
                labelText,
                style: TextStyle(
                  color: isFocused ? _primaryRed : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                  child: Center(
                    child: Icon(
                      icon,
                      color: isFocused ? _primaryRed : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    validator: validator,
                    textInputAction: textInputAction,
                    onTap: onTap,
                    readOnly: readOnly,
                    maxLines: maxLines,
                    style: const TextStyle(
                        color: Color(0xFF303030),
                        fontWeight: FontWeight.w500,
                        fontSize: 16),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: maxLines > 1 ? 12 : 14),
                      isDense: true,
                    ),
                  ),
                ),
                if (suffixWidget != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: suffixWidget,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====== Elegant Dropdown ======
  Widget _buildElegantDropdown<T>({
    required String labelText,
    required IconData icon,
    required Animation<Offset> slideAnimation,
    required FocusNode focusNode,
    required bool isFocused,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    T? value,
    String? hintText,
  }) {
    final Color borderCol = isFocused ? _primaryRed : Colors.grey.shade200;

    return SlideTransition(
      position: slideAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                      color: _primaryRed.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
          border: Border.all(color: borderCol, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 10, bottom: 6),
              child: Text(
                labelText,
                style: TextStyle(
                  color: isFocused ? _primaryRed : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
              child: DropdownButtonFormField<T>(
                focusNode: focusNode,
                initialValue: value,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: items,
                onChanged: onChanged,
                menuMaxHeight: 260,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String title,
    required String value,
    required BuildContext context,
    int index = 0,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animValue = (_animationController.value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: 0.9,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8.0),
            Text(value,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.0)),
          ],
        ),
      ),
    );
  }

  // ====== Email badge ======
  Widget _emailBadge({String? email, bool onDarkBg = false}) {
    final txt = Utils.formatEmptyValue(email ?? '');
    final bg = onDarkBg ? Colors.white.withOpacity(.15) : Colors.grey.shade100;
    final border =
        onDarkBg ? Colors.white.withOpacity(.35) : Colors.grey.shade300;
    final iconCol = onDarkBg ? Colors.white : Colors.grey.shade600;
    final textCol = onDarkBg ? Colors.white : Colors.grey.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: iconCol),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              txt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: textCol),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('id', 'ID'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Builder(
        builder: (ctx) {
          _lctx = ctx;

          return BlocConsumer<GuardianPhotoCubit, GuardianPhotoState>(
            listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
            listener: (context, state) async {
              if (state is GuardianPhotoSuccess) {
                ScaffoldMessenger.of(_lctx ?? context).hideCurrentSnackBar();
                ScaffoldMessenger.of(_lctx ?? context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        // Icon dengan background circle
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text message
                        Expanded(
                          child: Text(
                            'Profil berhasil diperbarui',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green[600]!,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    duration: const Duration(seconds: 3),
                    elevation: 6,
                  ),
                );

                final oldUrl = _currentImageUrl ?? '';
                if (oldUrl.isNotEmpty) {
                  await CachedNetworkImage.evictFromCache(oldUrl);
                }
                final freshUrl = _withCacheBuster(state.data.image ?? '');

                setState(() {
                  _currentImageUrl = freshUrl;
                  _pendingFile = null;
                  _guardian = state.data;

                  _firstNameC.text = _guardian.firstName ?? '';
                  _lastNameC.text = _guardian.lastName ?? '';

                  _selectedGenderApi = genderAnyToApi(_guardian.gender);

                  _selectedDob = _parseApiDob(_guardian.dob);
                  _dobC.text =
                      _selectedDob != null ? displayIndo(_selectedDob!) : '';

                  _mobileC.text = _guardian.mobile ?? '';
                  _currentAddressC.text = _guardian.currentAddress ?? '';
                  _permanentAddressC.text = _guardian.permanentAddress ?? '';
                  _occupationC.text = _guardian.occupation ?? '';
                });

                context.read<AuthCubit>().updateParentProfile(state.data);
              } else if (state is GuardianPhotoFailure) {
                ScaffoldMessenger.of(_lctx ?? context).hideCurrentSnackBar();
                ScaffoldMessenger.of(_lctx ?? context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gagal menyimpan: ${state.errorMessage}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFD32F2F),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    duration: const Duration(seconds: 4),
                    elevation: 6,
                  ),
                );
              }
            },
            builder: (context, state) {
              final bool isLoading = state is GuardianPhotoInProgress;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: MediaQuery.of(ctx).size.width * 0.9,
                    margin:
                        const EdgeInsets.only(right: 20, left: 20, bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: containerColor,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            spreadRadius: 2,
                            blurRadius: 12,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile section
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Profile photo
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 600),
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                      scale: value, child: child);
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 90.0,
                                      height: 90.0,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                              color: primaryColor
                                                  .withOpacity(0.25),
                                              spreadRadius: 2,
                                              blurRadius: 10,
                                              offset: const Offset(0, 3))
                                        ],
                                      ),
                                      child: Hero(
                                        tag: 'guardian_${widget.guardian.id}',
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                primaryColor,
                                                secondaryColor
                                              ],
                                            ),
                                          ),
                                          child: CustomUserProfileImageWidget(
                                            key: ValueKey(
                                                _currentImageUrl ?? ""),
                                            profileUrl: _currentImageUrl ?? "",
                                          ),
                                        ),
                                      ),
                                    ),
                                    // edit foto
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: InkWell(
                                        onTap:
                                            isLoading ? null : _onChangeProfile,
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          width: 35,
                                          height: 35,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2))
                                            ],
                                            border: Border.all(
                                                color: primaryColor
                                                    .withOpacity(0.2),
                                                width: 1),
                                          ),
                                          child: Center(
                                            child: isLoading
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2))
                                                : Icon(Icons.camera_alt,
                                                    size: 20,
                                                    color: primaryColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 20),

                              // Name + Email
                              Expanded(
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _animationController.value,
                                      child: Transform.translate(
                                        offset: Offset(
                                            0,
                                            20 *
                                                (1 -
                                                    _animationController
                                                        .value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        Utils.formatEmptyValue(
                                            _guardian.getFullName()),
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: _emailBadge(
                                                email: _guardian.email,
                                                onDarkBg: false),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          onPressed: isLoading
                                              ? null
                                              : _onEditFullProfile,
                                          icon: const Icon(Icons.edit_outlined),
                                          label: const Text('Edit Profil'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(
                              color: primaryColor.withOpacity(0.15),
                              thickness: 1.5),
                        ),

                        // Detail
                        _buildDetailItem(
                          context: ctx,
                          title: Utils.getTranslatedLabel(phoneNumberKey),
                          value: Utils.formatEmptyValue(_guardian.mobile ?? ""),
                          index: 1,
                        ),
                        _buildDetailItem(
                          context: ctx,
                          title: Utils.getTranslatedLabel(addressKey),
                          value: Utils.formatEmptyValue(
                              _guardian.currentAddress ?? ""),
                          index: 2,
                        ),
                        _buildDetailItem(
                          context: ctx,
                          title: "Alamat Permanen",
                          value: Utils.formatEmptyValue(
                              _guardian.permanentAddress ?? ""),
                          index: 3,
                        ),
                        _buildDetailItem(
                          context: ctx,
                          title: "Jenis Kelamin",
                          value: Utils.formatEmptyValue(
                              genderApiToUiTitle(_guardian.gender)),
                          index: 4,
                        ),
                        _buildDetailItem(
                          context: ctx,
                          title: "Tanggal Lahir",
                          value: Utils.formatEmptyValue(_selectedDob != null
                              ? displayIndo(_selectedDob!)
                              : ''),
                          index: 5,
                        ),
                        _buildDetailItem(
                          context: ctx,
                          title: "Pekerjaan",
                          value: Utils.formatEmptyValue(
                              _guardian.occupation ?? ""),
                          index: 6,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickPhotoSheet(GuardianPhotoCubit photoCubit) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // grab handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),

              // header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt_outlined, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ubah Foto Profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      iconn: Icons.photo_library_outlined,
                      label: 'Galeri',
                      onTap: () async {
                        Navigator.pop(_lctx ?? context);
                        await _pickAndUpload(ImageSource.gallery, photoCubit);
                      },
                      accent: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      iconn: Icons.photo_camera_outlined,
                      label: 'Kamera',
                      onTap: () async {
                        Navigator.pop(_lctx ?? context);
                        await _pickAndUpload(ImageSource.camera, photoCubit);
                      },
                      accent: secondaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Perubahan akan diunggah setelah Anda memilih foto.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _PinnedHeader({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Colors.transparent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeader oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData iconn;
  final String label;
  final VoidCallback onTap;
  final Color accent;

  const _QuickActionCard({
    Key? key,
    required this.iconn,
    required this.label,
    required this.onTap,
    required this.accent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(iconn, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}
