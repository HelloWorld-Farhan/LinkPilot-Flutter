class UrlParser {
  static String extractCompanyName(String urlString) {
    try {
      if (!urlString.startsWith('http')) {
        urlString = 'https://$urlString';
      }
      Uri uri = Uri.parse(urlString);
      String host = uri.host;

      // Remove www. if present
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }

      // Split by dot
      List<String> parts = host.split('.');
      
      // Look for common subdomains and remove them
      List<String> commonSubdomains = ['careers', 'jobs', 'about', 'boards', 'greenhouse', 'lever', 'workable'];
      if (parts.length > 2 && commonSubdomains.contains(parts.first.toLowerCase())) {
        parts.removeAt(0);
      }

      // The company name is usually the first part now
      if (parts.isNotEmpty) {
        String company = parts.first;
        // Capitalize first letter
        return company[0].toUpperCase() + company.substring(1);
      }

      return host;
    } catch (e) {
      return urlString;
    }
  }

  static bool isValidUrl(String urlString) {
    final regex = RegExp(
      r'^(https?:\/\/)?([\w\d-]+\.)+[\w\d-]+(\/[\w\d-./?%&=]*)?$',
      caseSensitive: false,
    );
    return regex.hasMatch(urlString);
  }

  static bool isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
      caseSensitive: false,
    );
    return regex.hasMatch(email);
  }
}
