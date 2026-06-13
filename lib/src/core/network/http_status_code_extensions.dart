extension HttpStatusCodeExtensions on int? {
  bool get isSuccessStatusCode {
    final int? code = this;
    return code != null && code >= 200 && code < 300;
  }
}
