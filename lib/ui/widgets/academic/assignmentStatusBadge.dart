import 'package:eschool/data/models/academic/assignment.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';

class AssignmentStatusBadge extends StatelessWidget {
  final Assignment assignment;

  const AssignmentStatusBadge({
    Key? key,
    required this.assignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if assignment is submitted and graded
    if (assignment.assignmentSubmission.id != 0 &&
        assignment.assignmentSubmission.points > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16.0,
            ),
            const SizedBox(width: 4.0),
            Text(
              "${Utils.getTranslatedLabel(acceptedKey)} ${assignment.assignmentSubmission.points}/${assignment.points}",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      );
    } else if (assignment.assignmentSubmission.status == 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_late,
              color: Colors.red,
              size: 16.0,
            ),
            const SizedBox(width: 4.0),
            Text(
              Utils.getTranslatedLabel(rejectedKey),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      );
    } else if (assignment.assignmentSubmission.id != 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pending,
              color: Colors.blue,
              size: 16.0,
            ),
            const SizedBox(width: 4.0),
            Text(
              Utils.getTranslatedLabel(submittedKey),
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      );
    } else {
      // Not submitted → show yellow if still before due date, red if overdue
      final bool beforeDueDate = DateTime.now().isBefore(assignment.dueDate);
      final Color badgeColor = beforeDueDate ? Colors.amber : Colors.red;
      final IconData badgeIcon =
          beforeDueDate ? Icons.info_rounded : Icons.assignment_late;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badgeIcon,
              color: badgeColor,
              size: 16.0,
            ),
            const SizedBox(width: 4.0),
            Text(
              Utils.getTranslatedLabel(
                  beforeDueDate ? assignedKey : notSubmittedKey),
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      );
    }
  }
}
