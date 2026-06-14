/// Centralized URL safety checks for externally-sourced links.
///
/// AI output, citations, and API-provided URLs must never be opened blindly.
/// These helpers enforce an https-only policy and host allowlisting.
class UrlSecurity {
  UrlSecurity._();

  /// Returns true when [rawUrl] is a well-formed `https` URL with a host.
  ///
  /// Rejects `javascript:`, `data:`, custom schemes, and malformed input.
  /// Use for any link sourced from AI responses or citations.
  static bool isSafeExternalUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return false;
    if (!uri.hasScheme || uri.scheme.toLowerCase() != 'https') return false;
    if (uri.host.isEmpty) return false;
    return true;
  }

  /// Returns true when [rawUrl] is https and its host is covered by
  /// [allowedHosts]. A host matches when it equals an allowed host or is a
  /// subdomain of one (e.g. `checkout.stripe.com` matches `stripe.com`).
  static bool isAllowedHost(String rawUrl, Iterable<String> allowedHosts) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return false;
    if (!uri.hasScheme || uri.scheme.toLowerCase() != 'https') return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    for (final allowed in allowedHosts) {
      final normalized = allowed.toLowerCase();
      if (host == normalized || host.endsWith('.$normalized')) {
        return true;
      }
    }
    return false;
  }
}
