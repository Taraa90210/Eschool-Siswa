import 'package:flutter/material.dart';

class ContactForm extends StatefulWidget {
  final Function({
    required String name,
    required String email,
    required String subject,
    required String message,
    required String type,
  }) onSubmit;
  final bool isLoading;
  final String? initialName;
  final String? initialEmail;
  final bool isStudent; // Add flag to indicate if user is a student
  final String? studentInfo; // Additional info text for students

  const ContactForm({
    Key? key,
    required this.onSubmit,
    this.isLoading = false,
    this.initialName,
    this.initialEmail,
    this.isStudent = false,
    this.studentInfo,
  }) : super(key: key);

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedType = 'inquiry';
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    // Set initial values for name and email
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _subjectController.addListener(_validateForm);
    _messageController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _nameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _subjectController.text.trim().isNotEmpty &&
          _messageController.text.trim().isNotEmpty &&
          _isValidEmail(_emailController.text.trim());
    });
  }

  bool _isValidEmail(String email) {
    // For students, accept any non-empty string as "email"
    // since it might be admission number in email format
    if (widget.isStudent) {
      return email.trim().isNotEmpty;
    }
    // For non-students (parents), validate proper email format
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selection
            _buildTypeSelector(),
            const SizedBox(height: 20.0),
            
            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap Anda',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            
            // Email Field
            _buildTextField(
              controller: _emailController,
              label: widget.isStudent ? 'ID Siswa / Email' : 'Email',
              hint: widget.isStudent ? 'Nomor Induk / Email Anda' : 'contoh@email.com',
              icon: Icons.email_outlined,
              keyboardType: widget.isStudent ? TextInputType.text : TextInputType.emailAddress,
              readOnly: widget.isStudent && widget.initialEmail != null && widget.initialEmail!.isNotEmpty,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return widget.isStudent ? 'ID Siswa tidak boleh kosong' : 'Email tidak boleh kosong';
                }
                if (!widget.isStudent && !_isValidEmail(value.trim())) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            // Info box for students
            if (widget.isStudent && widget.studentInfo != null) ...[
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        widget.studentInfo!,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 12.0,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16.0),
            
            // Subject Field
            _buildTextField(
              controller: _subjectController,
              label: 'Subjek',
              hint: 'Masukkan subjek pesan Anda',
              icon: Icons.subject,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Subjek tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            
            // Message Field
            _buildTextField(
              controller: _messageController,
              label: 'Pesan',
              hint: 'Tuliskan pesan atau laporan Anda di sini...',
              icon: Icons.message_outlined,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pesan tidak boleh kosong';
                }
                if (value.trim().length < 10) {
                  return 'Pesan minimal 10 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56.0,
              child: ElevatedButton(
                onPressed: _isFormValid && !widget.isLoading ? _submitForm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid && !widget.isLoading
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20.0,
                        width: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Kirim Pesan',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Pesan',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                'inquiry',
                'Pertanyaan',
                Icons.help_outline,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: _buildTypeOption(
                'report',
                'Laporan',
                Icons.report_outlined,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? color
                : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 24.0,
            ),
            const SizedBox(height: 8.0),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? color 
                    : Colors.grey.shade700,
                fontSize: 14.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          textInputAction: keyboardType == TextInputType.emailAddress 
              ? TextInputAction.next 
              : maxLines > 1 
                  ? TextInputAction.newline 
                  : TextInputAction.next,
          enableSuggestions: true,
          autocorrect: false,
          style: TextStyle(
            color: readOnly 
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 16.0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
