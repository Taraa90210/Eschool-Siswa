import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class ExamFiltersContainer extends StatefulWidget {
  final Function(int) onTapSubject;
  final int selectedExamFilterIndex;

  const ExamFiltersContainer({
    Key? key,
    required this.onTapSubject,
    required this.selectedExamFilterIndex,
  }) : super(key: key);

  @override
  State<ExamFiltersContainer> createState() => _ExamFiltersContainerState();
}

class _ExamFiltersContainerState extends State<ExamFiltersContainer> {
  late final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE), // Light gray background that works with white
          borderRadius: BorderRadius.circular(12.0),
          // Removed the boxShadow property
        ),
        child: ListView.builder(
          controller: _scrollController,
          itemBuilder: (context, index) {
            final bool isSelected = widget.selectedExamFilterIndex == index;
            
            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  return;
                }

                final selectedFilterIdIndex = widget.selectedExamFilterIndex;

                _scrollController.animateTo(
                  _scrollController.offset +
                      (index > selectedFilterIdIndex ? 1 : -1) *
                          MediaQuery.of(context).size.width *
                          (0.2),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );

                widget.onTapSubject(index);
              },
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 4.0, 
                  vertical: 5.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                child: Text(
                  Utils.getTranslatedLabel(examFilters[index]),
                  style: TextStyle(
                    color: isSelected 
                      ? Colors.white 
                      : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
          itemCount: examFilters.length,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
        ),
      ),
    );
  }
}
