import 'package:eschool/data/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContactCard extends StatefulWidget {
  final Contact contact;
  final VoidCallback? onTap;

  const ContactCard({
    Key? key,
    required this.contact,
    this.onTap,
  }) : super(key: key);

  @override
  State<ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<ContactCard> {
  
  @override
  void initState() {
    super.initState();
  }

  String _getFormattedDate() {
    final DateTime date = widget.contact.createdAt;
    final DateFormat formatter = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAdminReply = widget.contact.adminReply != null && widget.contact.adminReply!.isNotEmpty;
    
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: hasAdminReply 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                : Colors.grey.shade100,
            width: hasAdminReply ? 2.0 : 1.5,
          ),
          boxShadow: [
            // Outer shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            // Inner glow untuk card yang sudah dibalas
            if (hasAdminReply)
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 0),
                spreadRadius: -3,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row pertama: Icon dan Subject dengan Badge Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon besar merepresentasikan jenis pesan
                      _buildModernTypeIcon(),
                      const SizedBox(width: 16.0),
                      
                      // Subject dan Badge Status
                      Expanded(
                        child: Row(
                          children: [
                            // Subject - Bold & Modern
                            Expanded(
                              child: Text(
                                widget.contact.subject,
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            // Badge Status di sebelah kanan subject
                            _buildStatusBadge(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Message Container - Kontainer khusus untuk pesan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon, Label, dan Tanggal
                        Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16.0,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              'Pesan',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            // Tanggal
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12.0,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  _getFormattedDate(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        
                        // Isi Pesan
                        Text(
                          widget.contact.message,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13.0,
                            height: 1.5,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 14.0),
                  
                  // Divider modern dengan gradient
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey.shade200,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                        
                  const SizedBox(height: 16.0),
                  
                  // Footer - Badge Jenis & Detail Button
                  Row(
                    children: [
                      // Enhanced Badge Jenis Pesan
                      _buildEnhancedTypeBadge(),
                      const Spacer(),
                      // Button Lihat Detail (compact)
                      _buildDetailButton(),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // Icon besar modern dengan gradient
  Widget _buildModernTypeIcon() {
    IconData icon;
    List<Color> gradientColors;
    Color iconColor;

    if (widget.contact.isInquiry) {
      icon = Icons.chat_bubble_outline_rounded;
      gradientColors = [Colors.blue.shade400, Colors.blue.shade600];
      iconColor = Colors.white;
    } else {
      icon = Icons.warning_amber_rounded;
      gradientColors = [Colors.orange.shade400, Colors.orange.shade600];
      iconColor = Colors.white;
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 26.0,
      ),
    );
  }

  // Enhanced Badge untuk tipe pesan dengan gradient dan icon (compact & ukuran sama)
  Widget _buildEnhancedTypeBadge() {
    Color badgeColor;
    List<Color> gradientColors;
    String label;
    IconData icon;

    if (widget.contact.isInquiry) {
      badgeColor = Colors.blue.shade600;
      gradientColors = [Colors.blue.shade500, Colors.blue.shade700];
      label = 'Pertanyaan';
      icon = Icons.help_outline_rounded;
    } else {
      badgeColor = Colors.orange.shade600;
      gradientColors = [Colors.orange.shade500, Colors.orange.shade700];
      label = 'Laporan';
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Button Lihat Detail (Compact)
  Widget _buildDetailButton() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Lihat Detail',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.all(3.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Badge Status - untuk Baru atau Sudah Dibalas
  Widget _buildStatusBadge() {
    final bool hasAdminReply = widget.contact.adminReply != null && widget.contact.adminReply!.isNotEmpty;
    final bool isNew = widget.contact.status == 'new';
    
    Color badgeColor;
    String label;
    IconData icon;

    if (hasAdminReply || widget.contact.status == 'replied') {
      badgeColor = Colors.blue.shade600;
      label = 'Dibalas';
      icon = Icons.mark_email_read_rounded;
    } else if (isNew) {
      badgeColor = Colors.green.shade600;
      label = 'Baru';
      icon = Icons.fiber_new_rounded;
    } else {
      badgeColor = Colors.grey.shade600;
      label = 'Selesai';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor,
            badgeColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.0,
            color: Colors.white,
          ),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }


}
