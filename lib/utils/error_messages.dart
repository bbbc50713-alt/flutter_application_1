/// Utility class for user-friendly error messages
class ErrorMessages {
  ErrorMessages._();

  /// Database related errors
  static const String databaseError = 'Unable to save data. Please try again.';
  static const String databaseReadError = 'Unable to load data. Please try again.';
  static const String databaseWriteError = 'Unable to save changes. Please try again.';

  /// Test related errors
  static const String testNotFound = 'Test not found. It may have been deleted.';
  static const String testAlreadyStopped = 'This test has already been stopped.';
  static const String noOngoingTests = 'No ongoing tests available.';
  static const String testCreationFailed = 'Failed to create test. Please try again.';

  /// Image related errors
  static const String imagePickError = 'Failed to pick image. Please try again.';
  static const String imageSaveError = 'Failed to save image. Please try again.';

  /// Report related errors
  static const String reportGenerationError = 'Failed to generate report. Please try again.';
  static const String reportShareError = 'Failed to share report. Please try again.';
  static const String reportEmailError = 'Failed to send email. Please try again.';

  // Email specific errors
  static const String emailNotAvailable = 'No email app detected. Please install Gmail or Outlook.';
  static const String emailConfirmTitle = 'Send Report';
  static const String emailConfirmMessage = 'The email app will open with the report attached. Please confirm you are connected to the internet and complete sending.';
  static const String emailFeedbackTitle = 'Send Status';
  static const String emailFeedbackMessage = 'Was the email sent successfully?';
  static const String emailSentSuccess = 'Great! The report has been sent.';
  static const String emailRetryOptions = 'You can try:\n1) Check network connection\n2) Check email login\n3) Resend the report';
  static const String emailCopySuccess = 'Report content copied to clipboard.';
  static const String emailFallbackTitle = 'Unable to Open Email';
  static const String emailFallbackOption1 = 'Copy Email Content';
  static const String emailFallbackOption2 = 'Share PDF';

  /// Form validation errors
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPhone = 'Please enter a valid phone number';
  static const String invalidVoltage = 'Please enter a valid voltage reading';

  /// Network errors
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';

  /// Permission errors
  static const String cameraPermissionDenied = 'Camera permission denied. Please enable it in settings.';
  static const String storagePermissionDenied = 'Storage permission denied. Please enable it in settings.';

  /// Generic error message
  static const String unknownError = 'An unexpected error occurred. Please try again.';

  /// Get user-friendly error message from exception
  static String fromException(Exception e) {
    final errorString = e.toString().toLowerCase();

    // Database errors
    if (errorString.contains('database') || errorString.contains('sqlite')) {
      return databaseError;
    }

    // Image errors
    if (errorString.contains('image') || errorString.contains('photo')) {
      return imagePickError;
    }

    // Network errors
    if (errorString.contains('network') || errorString.contains('socket')) {
      return networkError;
    }

    // Permission errors
    if (errorString.contains('permission')) {
      return cameraPermissionDenied;
    }

    // Return generic error for unknown exceptions
    return unknownError;
  }
}
