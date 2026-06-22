import 'package:flutter/material.dart';

class SignUpInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;

  const SignUpInputField({
    Key? key,
    required this.controller,
    required this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  }) : super(key: key);

  InputDecoration _inputDecoration(String hint, bool hasError) {
    final OutlineInputBorder commonBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: hasError ? const Color(0xFFD84848) : const Color(0xFF1B84B5),
        width: 4,
      ),
      borderRadius: BorderRadius.circular(20),
    );

    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1CB1F5),
      enabledBorder: commonBorder,
      focusedBorder: commonBorder,
      errorBorder: commonBorder,
      focusedErrorBorder: commonBorder,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white, fontSize: 17),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double inputHeight = 65;
    const double errorCollapsedHeight = 6;
    const double errorExpandedHeight = 22;

    final TextStyle errorStyle = const TextStyle(
      color: Color(0xFFD84848),
      fontSize: 13,
      height: 1.1,
    );

    final bool hasError = (errorText != null && errorText!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: inputHeight,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: _inputDecoration(hint, hasError),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 1),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: hasError ? errorExpandedHeight : errorCollapsedHeight,
              maxHeight: hasError ? errorExpandedHeight : errorCollapsedHeight,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: hasError
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          const Icon(
                            Icons.error_rounded,
                            size: 22,
                            color: Color(0xFFD84848),
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            errorText!,
                            style: errorStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
