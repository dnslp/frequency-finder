import SwiftUI
import WebKit

struct ReadingPassageWebView: View {
  let url = URL(string: "https://dnslp.github.io/reading-passage/")!
  @State private var queryItems: [URLQueryItem] = []

  var body: some View {
    LegacyWebView(url: url) { newURL in
      queryItems = URLComponents(
        url: newURL,
        resolvingAgainstBaseURL: false
      )?.queryItems ?? []
    }
    // … display queryItems …
  }
}

struct LegacyWebView: UIViewRepresentable {
  let url: URL
  let onURLChange: (URL) -> Void

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    webView.load(URLRequest(url: url))
    return webView
  }

  func updateUIView(_ uiView: WKWebView, context: Context) { }

  func makeCoordinator() -> Coordinator {
    Coordinator(onURLChange)
  }

  class Coordinator: NSObject, WKNavigationDelegate {
    let callback: (URL) -> Void
    init(_ cb: @escaping (URL) -> Void) { self.callback = cb }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navAction: WKNavigationAction,
      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
      if let url = navAction.request.url {
        callback(url)
      }
      decisionHandler(.allow)
    }
  }
}
#Preview {
    ReadingPassageWebView()
}