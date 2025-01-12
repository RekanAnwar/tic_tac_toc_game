String getAuthErrorMessage(String code) {
  switch (code) {
    case 'weak-password':
      return 'Password should be at least 6 characters';
    case 'email-already-in-use':
      return 'An account already exists with this email';
    case 'invalid-email':
      return 'Please enter a valid email address';
    case 'operation-not-allowed':
      return 'Email/password accounts are not enabled';
    case 'user-disabled':
      return 'This account has been disabled';
    case 'user-not-found':
      return 'No account found with this email';
    case 'wrong-password':
      return 'Incorrect password';
    default:
      return 'An error occurred. Please try again later';
  }
}
