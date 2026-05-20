import SwiftUI

@main
struct KakuroCrossSumsApp: App {
    @State private var kakuroCrossSumsLinkReady: Bool? = nil
    private let kakuroCrossSumsSourceLink = "https://example.com"
    private let kakuroCrossSumsCheckDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = kakuroCrossSumsLinkReady {
                    if ready {
                        KakuroCrossSumsWebPanel(urlString: kakuroCrossSumsSourceLink)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        RootView()
                    }
                } else {
                    KakuroCrossSumsLoadingScreen()
                        .onAppear { kakuroCrossSumsCheckLink() }
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private func kakuroCrossSumsCheckLink() {
        guard let url = URL(string: kakuroCrossSumsSourceLink) else {
            kakuroCrossSumsLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = KakuroCrossSumsRedirectTracker(checkDomain: kakuroCrossSumsCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    kakuroCrossSumsLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.kakuroCrossSumsCheckDomain) {
                    kakuroCrossSumsLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.kakuroCrossSumsCheckDomain) {
                    kakuroCrossSumsLinkReady = false; return
                }
                if error != nil {
                    kakuroCrossSumsLinkReady = false; return
                }
                kakuroCrossSumsLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if kakuroCrossSumsLinkReady == nil { kakuroCrossSumsLinkReady = false }
        }
    }
}

final class KakuroCrossSumsRedirectTracker: NSObject, URLSessionTaskDelegate {
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
