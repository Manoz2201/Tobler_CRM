import 'package:flutter/material.dart';

/// Custom RadioGroup implementation to replace deprecated RadioListTile usage
/// This can be easily replaced with Flutter's RadioGroup when it becomes available
class CustomRadioGroup<T> extends StatelessWidget {
  final T? value;
  final ValueChanged<T?> onChanged;
  final List<CustomRadioOption<T>> options;
  final EdgeInsetsGeometry? padding;

  const CustomRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        children: options.map((option) {
          return CustomRadioListTile<T>(
            value: option.value,
            groupValue: value,
            onChanged: onChanged,
            title: option.title,
            subtitle: option.subtitle,
            leading: option.leading,
            trailing: option.trailing,
          );
        }).toList(),
      ),
    );
  }
}

/// Custom RadioOption to define radio button options
class CustomRadioOption<T> {
  final T value;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;

  const CustomRadioOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });
}

/// Custom RadioListTile that doesn't use deprecated properties
class CustomRadioListTile<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;

  const CustomRadioListTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            // Custom radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Leading widget (if provided)
            if (leading != null) ...[leading!, const SizedBox(width: 16)],

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),

            // Trailing widget (if provided)
            if (trailing != null) ...[const SizedBox(width: 16), trailing!],
          ],
        ),
      ),
    );
  }
}
