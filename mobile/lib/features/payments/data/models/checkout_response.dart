
class CheckoutResponse {
  final bool success;
  final String url;
  final String message;

  CheckoutResponse({
    required this.success, 
    required this.url, 
    required this.message
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      success: json['success'] as bool? ?? false,
      url: json['url'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}
