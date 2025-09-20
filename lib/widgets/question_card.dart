import 'package:flutter/material.dart';
import '../models/quiz_model.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final dynamic selected; // int | List<int> | bool | String
  final void Function(dynamic) onSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textStyle = theme.textTheme;
    final initialText = selected is String ? selected as String : '';

    Widget _buildOptionTile({
      required Widget leading,
      required String label,
      required bool active,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          color: active ? cs.primary.withOpacity(0.12) : cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: active ? cs.primary : cs.onSurface.withOpacity(0.08),
              width: active ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: textStyle.bodyMedium)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: question text + points chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question.question,
                    style: textStyle.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (question.points != 0)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.primary.withOpacity(0.18)),
                    ),
                    child: Text(
                      '${question.points} pts',
                      style: textStyle.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content by type
            if (question.type == 'mcq')
              (question.correctIndexes != null &&
                      question.correctIndexes!.isNotEmpty)
                  ? Column(
                    children: List.generate(question.options.length, (i) {
                      final checked =
                          selected is List<int>
                              ? (selected as List<int>).contains(i)
                              : false;
                      return _buildOptionTile(
                        leading: Checkbox(
                          value: checked,
                          onChanged: (v) {
                            final cur = List<int>.from(
                              selected is List<int>
                                  ? selected as List<int>
                                  : [],
                            );
                            if (v == true) {
                              if (!cur.contains(i)) cur.add(i);
                            } else {
                              cur.remove(i);
                            }
                            onSelected(cur);
                          },
                          activeColor: cs.primary,
                        ),
                        label: question.options[i],
                        active: checked,
                        onTap: () {
                          final cur = List<int>.from(
                            selected is List<int> ? selected as List<int> : [],
                          );
                          if (cur.contains(i)) {
                            cur.remove(i);
                          } else {
                            cur.add(i);
                          }
                          onSelected(cur);
                        },
                      );
                    }),
                  )
                  : Column(
                    children: List.generate(question.options.length, (i) {
                      final isSelected =
                          selected is int ? selected as int == i : false;
                      return _buildOptionTile(
                        leading: Radio<int>(
                          value: i,
                          groupValue: selected is int ? selected as int : -1,
                          onChanged: (v) => onSelected(v),
                          activeColor: cs.primary,
                        ),
                        label: question.options[i],
                        active: isSelected,
                        onTap: () => onSelected(i),
                      );
                    }),
                  )
            else if (question.type == 'tf')
              Column(
                children: [
                  _buildOptionTile(
                    leading: Radio<bool>(
                      value: true,
                      groupValue: selected is bool ? selected as bool : null,
                      onChanged: (v) => onSelected(v),
                      activeColor: cs.primary,
                    ),
                    label: 'True',
                    active: selected is bool ? selected as bool == true : false,
                    onTap: () => onSelected(true),
                  ),
                  _buildOptionTile(
                    leading: Radio<bool>(
                      value: false,
                      groupValue: selected is bool ? selected as bool : null,
                      onChanged: (v) => onSelected(v),
                      activeColor: cs.primary,
                    ),
                    label: 'False',
                    active:
                        selected is bool ? selected as bool == false : false,
                    onTap: () => onSelected(false),
                  ),
                ],
              )
            else
              // short answer
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextFormField(
                  initialValue: initialText,
                  minLines: 1,
                  maxLines: 4,
                  onChanged: (v) => onSelected(v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor:
                        theme.inputDecorationTheme.fillColor ??
                        cs.surfaceVariant.withOpacity(0.04),
                    hintText: 'Your answer',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
