class AssignRolesStyle {
  static const double slidableSizeRatio = 0.23;

  static double slidableExtentRatio(int slidablesLength) {
    return slidablesLength == 0 ? 1 : slidableSizeRatio * slidablesLength;
  }
}
