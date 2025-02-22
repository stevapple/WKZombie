//
// RenderOperation.swift
//
// Copyright (c) 2015 Mathias Koehnke (http://www.mathiaskoehnke.de)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import WebKit

//========================================

// MARK: RenderOperation

//========================================

typealias RequestBlock = (_ operation: RenderOperation) -> Void

internal class RenderOperation: Operation {
    fileprivate(set) weak var webView: WKWebView?
    fileprivate var timeout: Timer?
    fileprivate let timeoutInSeconds: TimeInterval
    fileprivate var stopRunLoop: Bool = false

    var loadMediaContent: Bool = true
    var showNetworkActivity: Bool = true
    var requestBlock: RequestBlock?
    var authenticationBlock: AuthenticationHandler?
    var postAction: PostAction = .none

    internal fileprivate(set) var result: Data?
    internal fileprivate(set) var response: URLResponse?
    internal fileprivate(set) var error: Error?

    fileprivate var _executing: Bool = false
    override var isExecuting: Bool {
        get {
            return self._executing
        }
        set {
            if self._executing != newValue {
                willChangeValue(forKey: "isExecuting")
                self._executing = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }

    fileprivate var _finished: Bool = false
    override var isFinished: Bool {
        get {
            return self._finished
        }
        set {
            if self._finished != newValue {
                willChangeValue(forKey: "isFinished")
                self._finished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }

    init(webView: WKWebView, timeoutInSeconds: TimeInterval = 30.0) {
        self.timeoutInSeconds = timeoutInSeconds
        super.init()
        self.webView = webView
    }

    override func start() {
        if self.isCancelled {
            return
        } else {
            Logger.log("\(name ?? String())")
            Logger.log("[", lineBreak: false)
            self.isExecuting = true
            self.startTimeout()

            // Wait for WKWebView to finish loading before starting the operation.
            self.wait {
                guard let webView = webView else {
                    return false
                }
                var isLoading = false
                dispatch_sync_on_main_thread {
                    isLoading = webView.isLoading
                }
                return !isLoading
            }

            self.setupReferences()
            self.requestBlock?(self)

            // Loading
            self.wait { [unowned self] in self.stopRunLoop }
        }
    }

    func wait(_ condition: () -> Bool) {
        let updateInterval: TimeInterval = 0.1
        var loopUntil = Date(timeIntervalSinceNow: updateInterval)
        while condition() == false && RunLoop.current.run(mode: .default, before: loopUntil) {
            loopUntil = Date(timeIntervalSinceNow: updateInterval)
            Logger.log(".", lineBreak: false)
        }
    }

    func completeRendering(_ webView: WKWebView?, result: Data? = nil, error: Error? = nil) {
        self.stopTimeout()

        if self.isExecuting == true && self.isFinished == false {
            self.result = result ?? self.result
            self.error = error ?? self.error

            self.cleanupReferences()

            self.isExecuting = false
            self.isFinished = true

            Logger.log("]\n")
        }
    }

    override func cancel() {
        Logger.log("Cancelling Rendering - \(String(describing: name))")
        super.cancel()
        self.stopTimeout()
        self.cleanupReferences()
        self.isExecuting = false
        self.isFinished = true
    }

    // MARK: Helper Methods

    fileprivate func startTimeout() {
        self.stopRunLoop = false
        self.timeout = Timer(timeInterval: self.timeoutInSeconds, target: self, selector: #selector(RenderOperation.cancel), userInfo: nil, repeats: false)
        RunLoop.current.add(self.timeout!, forMode: .default)
    }

    fileprivate func stopTimeout() {
        self.timeout?.invalidate()
        self.timeout = nil
        self.stopRunLoop = true
    }

    fileprivate func setupReferences() {
        dispatch_sync_on_main_thread {
            webView?.configuration.userContentController.add(self, name: "doneLoading")
            webView?.navigationDelegate = self
        }
    }

    fileprivate func cleanupReferences() {
        dispatch_sync_on_main_thread {
            webView?.navigationDelegate = nil
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: "doneLoading")
            webView = nil
            authenticationBlock = nil
        }
    }
}

//========================================

// MARK: WKScriptMessageHandler

//========================================

extension RenderOperation: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // None of the content loaded after this point is necessary (images, videos, etc.)
        if let webView = message.webView {
            if message.name == "doneLoading" && self.loadMediaContent == false {
                if let url = webView.url, response == nil {
                    response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
                }
                webView.stopLoading()
                self.webView(webView, didFinish: nil)
            }
        }
    }
}

//========================================

// MARK: WKNavigationDelegate

//========================================

extension RenderOperation: WKNavigationDelegate {
    private func setNetworkActivityIndicatorVisible(visible: Bool) {
        #if os(iOS)
        if self.showNetworkActivity { UIApplication.shared.isNetworkActivityIndicatorVisible = visible }
        #endif
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.setNetworkActivityIndicatorVisible(visible: self.showNetworkActivity)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        self.response = navigationResponse.response
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.setNetworkActivityIndicatorVisible(visible: false)
        if let response = response as? HTTPURLResponse, let _ = completionBlock {
            let successRange = 200 ..< 300
            if !successRange.contains(response.statusCode) {
                self.error = error
                self.completeRendering(webView)
            }
        }
        Logger.log(error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.setNetworkActivityIndicatorVisible(visible: false)
        switch self.postAction {
        case .wait, .validate: handlePostAction(self.postAction, webView: webView)
        case .none: finishedLoading(webView)
        }
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let authenticationBlock = authenticationBlock {
            let authenticationResult = authenticationBlock(challenge)
            completionHandler(authenticationResult.0, authenticationResult.1)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.error = error
        self.completeRendering(webView)
        Logger.log(error.localizedDescription)
    }
}

//========================================

// MARK: Validation

//========================================

extension RenderOperation {
    func finishedLoading(_ webView: WKWebView) {
        webView.evaluateJavaScript("\(Renderer.scrapingCommand);") { [weak self] result, _ in
            self?.result = (result as? String)?.data(using: String.Encoding.utf8)
            self?.completeRendering(webView)
        }
    }

    func validate(_ condition: String, webView: WKWebView) {
        if self.isFinished == false && isCancelled == false {
            webView.evaluateJavaScript(condition) { [weak self] result, _ in
                if let result = result as? Bool, result == true {
                    self?.finishedLoading(webView)
                } else {
                    delay(0.5, completion: {
                        self?.validate(condition, webView: webView)
                    })
                }
            }
        }
    }

    func waitAndFinish(_ time: TimeInterval, webView: WKWebView) {
        delay(time) {
            self.finishedLoading(webView)
        }
    }

    func handlePostAction(_ postAction: PostAction, webView: WKWebView) {
        switch postAction {
        case .validate(let script): self.validate(script, webView: webView)
        case .wait(let time): self.waitAndFinish(time, webView: webView)
        default: Logger.log("Something went wrong!")
        }
        self.postAction = .none
    }
}
