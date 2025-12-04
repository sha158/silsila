class Validators {
  static String? validateStudentId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter Student ID';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      final phoneRegex = RegExp(r'^\d{10,}$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  static String? validateSubject(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter subject name';
    }
    return null;
  }

  static String? validateClassPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length != 6) {
      return 'Password must be exactly 6 digits';
    }
    final numericRegex = RegExp(r'^\d{6}$');
    if (!numericRegex.hasMatch(value)) {
      return 'Password must be 6 digits';
    }
    return null;
  }
}
