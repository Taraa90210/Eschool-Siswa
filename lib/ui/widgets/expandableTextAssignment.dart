import 'package:flutter/material.dart';

class ExpandableTextAssignment extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;

  const ExpandableTextAssignment({
    Key? key,
    required this.text,
    required this.style,
    this.maxLines = 2,
  }) : super(key: key);

  @override
  _ExpandableTextAssignmentState createState() => _ExpandableTextAssignmentState();
}

class _ExpandableTextAssignmentState extends State<ExpandableTextAssignment> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowed = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: Text(
                widget.text,
                style: widget.style,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                widget.text,
                style: widget.style,
              ),
              crossFadeState:
                  isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 300),
            ),
            if (isOverflowed)
              InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                splashColor: Colors.red.withValues(alpha: 0.8),
                highlightColor: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    isExpanded ? 'Lebih Sedikit' : 'Lebih Banyak',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              )
          ],
        );
      },
    );
  }
}