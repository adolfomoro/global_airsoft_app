import 'package:flutter/material.dart';

mixin AuthFormSubmissionMixin<T extends StatefulWidget> on State<T> {
  bool _hasSubmitted = false;

  bool get hasSubmitted => _hasSubmitted;

  AutovalidateMode get formAutovalidateMode => hasSubmitted
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  void markFormSubmitted() {
    if (_hasSubmitted) {
      return;
    }

    setState(() {
      _hasSubmitted = true;
    });
  }

  bool validateSubmittedForm(GlobalKey<FormState> formKey) {
    markFormSubmitted();
    final FormState? formState = formKey.currentState;
    return formState?.validate() ?? false;
  }
}
