import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
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
      body: Stack(
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

