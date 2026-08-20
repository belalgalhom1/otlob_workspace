class PhoneUtils {
  /// Normalizes a phone number to the E.164 format with +20 prefix if missing.
  ///
  /// Logic:
  /// 1. Remove all non-digit characters (except '+').
  /// 2. If it starts with '+20', return it.
  /// 3. If it starts with '0' and is followed by digits, replace '0' with '+20'.
  /// 4. If it's a 10-digit number (common for Egyptian mobile without '0'), prepend '+20'.
  /// 5. Otherwise, prepend '+20' if it doesn't start with '+'.
  static String normalize(String phone) {
    if (phone.isEmpty) return phone;

    // Remove all whitespace and non-digit characters (except '+')
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+20')) {
      return cleaned;
    }

    if (cleaned.startsWith('0020')) {
      return '+20${cleaned.substring(4)}';
    }

    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    if (cleaned.startsWith('0')) {
      return '+20${cleaned.substring(1)}';
    }

    // Default to prepending +20 if no other rule matched and it's just digits
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '+20$cleaned';
    }

    return cleaned;
  }
}
