import 'package:eschool/ui/widgets/academic/assignmentsContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';

class AssignmentFilterBottomsheetContainer extends StatefulWidget {
  final AssignmentFilters initialAssignmentFilterValue;
  final Function changeAssignmentFilter;
  const AssignmentFilterBottomsheetContainer({
    Key? key,
    required this.initialAssignmentFilterValue,
    required this.changeAssignmentFilter,
  }) : super(key: key);

  @override
  State<AssignmentFilterBottomsheetContainer> createState() =>
      _AssignmentFilterBottomsheetContainerState();
}

class _AssignmentFilterBottomsheetContainerState
    extends State<AssignmentFilterBottomsheetContainer> {
  late AssignmentFilters _currentlySelectedAssignmentFilterValue =
      widget.initialAssignmentFilterValue;

  Widget _buildAssignmentFilterTile({
    required String title,
    required AssignmentFilters assignmentFilter,
  }) {
    final bool isSelected =
        _currentlySelectedAssignmentFilterValue == assignmentFilter;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color:
            isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        border: Border.all(
          color: isSelected
              ? Colors.red
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _currentlySelectedAssignmentFilterValue = assignmentFilter;
            });
            widget.changeAssignmentFilter(assignmentFilter);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: title.trim().split(" ").length > 1 ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.secondary,
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * (0.041),
        vertical: MediaQuery.of(context).size.height * (0.04),
      ),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Utils.bottomSheetTopRadius),
          topRight: Radius.circular(Utils.bottomSheetTopRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_alt,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 5),
              Text(
                Utils.getTranslatedLabel(sortByKey),
                style: TextStyle(
                  fontSize: 16.0,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, // 2 kolom
            childAspectRatio: 3.5, // rasio item agar tidak terlalu tinggi
            crossAxisSpacing: 3,
            mainAxisSpacing: 5,
            children: [
              _buildAssignmentFilterTile(
                title: Utils.getTranslatedLabel(assignedDateLatestKey),
                assignmentFilter: AssignmentFilters.assignedDateLatest,
              ),
              _buildAssignmentFilterTile(
                title: Utils.getTranslatedLabel(assignedDateOldestKey),
                assignmentFilter: AssignmentFilters.assignedDateOldest,
              ),
              _buildAssignmentFilterTile(
                title: Utils.getTranslatedLabel(dueDateLatestKey),
                assignmentFilter: AssignmentFilters.dueDateLatest,
              ),
              _buildAssignmentFilterTile(
                title: Utils.getTranslatedLabel(dueDateOldestKey),
                assignmentFilter: AssignmentFilters.dueDateOldest,
              ),
            ],
          )
        ],
      ),
    );
  }
}
