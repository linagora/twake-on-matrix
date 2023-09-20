T? tryCast<T>(dynamic value, {T? fallback}) {
  if (value != null && value is T) {
    return value;
  }

  return fallback;
}
