import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// WebView for handling Stripe checkout
class StripeCheckoutWebView extends StatefulWidget {
  final String checkoutUrl;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const StripeCheckoutWebView({
    super.key,
    required this.checkoutUrl,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<StripeCheckoutWebView> createState() => _StripeCheckoutWebViewState();
}

class _StripeCheckoutWebViewState extends State<StripeCheckoutWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _blockedUnsafeUrl = false;

  /// Hosts permitted inside the checkout WebView: Stripe's hosted checkout,
  /// plus the backend API host (success/cancel redirects come back to it).
  Set<String> get _allowedHosts {
    final hosts = <String>{'stripe.com', 'stripe.network', 'js.stripe.com'};
    final apiHost = Uri.tryParse(AppConfig.apiBaseUrl)?.host;
    if (apiHost != null && apiHost.isNotEmpty) {
      hosts.add(apiHost);
    }
    return hosts;
  }

  bool _isAllowed(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme.toLowerCase() != 'https') return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    return _allowedHosts.any(
      (allowed) => host == allowed || host.endsWith('.$allowed'),
    );
  }

  @override
  void initState() {
    super.initState();

    // Reject a checkout URL that is not https or not on an allowed host before
    // it is ever loaded into the JS-enabled WebView.
    if (!_isAllowed(widget.checkoutUrl)) {
      _blockedUnsafeUrl = true;
      logWarning('[StripeWebView] Blocked unsafe checkout URL');
      _isLoading = false;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (_isAllowed(request.url)) {
              return NavigationDecision.navigate;
            }
            logWarning('[StripeWebView] Blocked navigation to disallowed host');
            return NavigationDecision.prevent;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            logDebug('[StripeWebView] ${error.description}');
          },
          onUrlChange: (UrlChange change) {
            _handleUrlChange(change.url ?? '');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _handleUrlChange(String url) {
    // Check for Stripe success/cancel URLs
    // Stripe typically redirects to success_url or cancel_url
    if (url.contains('success') || url.contains('checkout/success')) {
      // Checkout successful
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        // Default behavior: navigate back and show success message
        if (mounted) {
          context.pop(true); // Return true to indicate success
        }
      }
    } else if (url.contains('cancel') || url.contains('checkout/cancel')) {
      // Checkout canceled
      if (widget.onCancel != null) {
        widget.onCancel!();
      } else {
        // Default behavior: navigate back
        if (mounted) {
          context.pop(false); // Return false to indicate cancel
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (widget.onCancel != null) {
              widget.onCancel!();
            } else {
              context.pop(false);
            }
          },
        ),
      ),
      body: _blockedUnsafeUrl
          ? const Center(
              child: Padding(
                padding: AppInsets.page,
                child: Text(
                  'This checkout link could not be verified and was blocked '
                  'for your security. Please try again or contact support.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}
