class Validators {
  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  // Validate password match
  static String? validatePasswordMatch(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi tidak boleh kosong';
    }
    if (value != password) {
      return 'Kata sandi tidak cocok';
    }
    return null;
  }

  // Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  // Validate title
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Judul tidak boleh kosong';
    }
    if (value.length < 5) {
      return 'Judul minimal 5 karakter';
    }
    return null;
  }

  // Validate content
  static String? validateContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konten tidak boleh kosong';
    }
    if (value.length < 10) {
      return 'Konten minimal 10 karakter';
    }
    return null;
  }
}
