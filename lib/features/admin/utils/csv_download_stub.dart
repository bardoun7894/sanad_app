/// Non-web stub for [downloadCsvOnWeb]. No-op on non-web platforms.
/// The billing screen is a web-only admin target, so this path is unused
/// at runtime but satisfies the Dart compiler for non-web builds.
// ignore_for_file: avoid_unused_element
void downloadCsvOnWeb(String content, String filename) {
  // No-op on non-web platforms.
}
