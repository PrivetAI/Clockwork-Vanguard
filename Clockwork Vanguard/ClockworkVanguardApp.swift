import SwiftUI

@main
struct ClockworkVanguardApp: App {
    @StateObject private var store = ProgressStore()
    @State private var vanguardLinkReady: Bool? = nil

    private let vanguardSourceLink = "https://example.com"
    private let vanguardCheckDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = vanguardLinkReady {
                    if ready {
                        // Fullscreen web panel — frame must respect the top safe
                        // area (notch) so page content never renders under it.
                        ClockworkVanguardWebPanel(urlString: vanguardSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootMenuView()
                            .environmentObject(store)
                    }
                } else {
                    ClockworkVanguardLoadingScreen()
                        .onAppear { probeVanguardLink() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func probeVanguardLink() {
        guard let url = URL(string: vanguardSourceLink) else {
            vanguardLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = VanguardRedirectTracker(checkDomain: vanguardCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    vanguardLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.vanguardCheckDomain) {
                    vanguardLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.vanguardCheckDomain) {
                    vanguardLinkReady = false; return
                }
                if error != nil {
                    vanguardLinkReady = false; return
                }
                vanguardLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if vanguardLinkReady == nil { vanguardLinkReady = false }
        }
    }
}

// MARK: - Redirect tracker

final class VanguardRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request) // never stop the redirect chain
    }
}
