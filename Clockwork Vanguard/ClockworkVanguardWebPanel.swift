import SwiftUI
import WebKit

// MARK: - WKWebView wrapper (launch gate + Settings privacy sheet)

struct ClockworkVanguardWebPanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        // Belt-and-suspenders only; the frame respecting the top safe area
        // (set by the presenter) is the real notch guarantee. NEVER .never.
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.isOpaque = true
        webView.backgroundColor = .black
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    // MUST stay empty — reloading here would trigger an infinite reload loop.
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Launch splash

struct ClockworkVanguardLoadingScreen: View {
    @State private var spin = false

    var body: some View {
        ZStack {
            Theme.bgDeep.edgesIgnoringSafeArea(.all)
            VStack(spacing: 28) {
                ZStack {
                    GearShape(teeth: 10)
                        .fill(Theme.brass, style: FillStyle(eoFill: true))
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: spin)
                    GearShape(teeth: 7)
                        .fill(Theme.patina, style: FillStyle(eoFill: true))
                        .frame(width: 52, height: 52)
                        .offset(x: 58, y: 44)
                        .rotationEffect(.degrees(spin ? -360 : 0))
                        .animation(.linear(duration: 3.4).repeatForever(autoreverses: false), value: spin)
                }
                .frame(width: 160, height: 160)

                Text("Clockwork Vanguard")
                    .font(.system(size: 26, weight: .heavy, design: .serif))
                    .foregroundColor(Theme.ivory)

                Text("Winding the mainspring...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.ivoryDim)
            }
        }
        .onAppear { spin = true }
    }
}
