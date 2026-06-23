//
//  ContactDetailWebView.swift
//
//  Created by Alam Monroy.
//

import SwiftUI
import WebKit

/// Bridges a WKWebView into SwiftUI to render the contact/partner detail
/// card defined in contact-detail.html (a native Web Component built with
/// Shadow DOM, not a framework).
struct ContactDetailWebView: UIViewRepresentable {
    let contact: ContactConfig

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false

        if let htmlURL = Bundle.main.url(forResource: "contact-detail", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No-op: data is injected once, after the initial page load
        // finishes (see Coordinator.didFinish below). If `contact` ever
        // needs to change while this view stays on screen, re-injecting
        // here would be the place to do it.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(contact: contact)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let contact: ContactConfig

        init(contact: ContactConfig) {
            self.contact = contact
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let payload: [String: Any?] = [
                "name": contact.name,
                "logoURL": contact.avatar,
                "description": contact.description,
                "websiteURL": contact.websiteURL,
                "ctaLabel": String(localized: "Visit Website"),
            ]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 }),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return
            }
            webView.evaluateJavaScript("renderContact(\(jsonString))")
            print("DEBUG payload enviado al WebView: \(jsonString)")
        }

        /// Intercepts taps on the "Visit Website" link so it opens in
        /// Safari instead of navigating away inside our WebView.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

#Preview("Full content") {
    ContactDetailWebView(contact: ContactConfig(
        id: 1,
        name: "Canada Goose",
        avatar: "https://ios-wrapper-test-kk-de916285ba09.herokuapp.com/resources/phone/WTNYC-Apr-2026/Canada-Goose-logo.png",
        imageURL: nil,
        description: "Premium outerwear engineered for the world's harshest climates, worn on expeditions from the Arctic to the Antarctic.",
        websiteURL: "https://www.canadagoose.com"
    ))
    .frame(height: 420)
}

#Preview("Minimal — no description or CTA") {
    ContactDetailWebView(contact: ContactConfig(
        id: 2,
        name: "Acme Corp",
        avatar: nil,
        imageURL: nil,
        description: nil,
        websiteURL: nil
    ))
    .frame(height: 420)
}
