//
// Tests.swift
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

import WKZombie
import XCTest

class Tests: XCTestCase {
    var browser: WKZombie!

    override func setUp() {
        super.setUp()
        self.browser = WKZombie(name: "WKZombie Tests")
    }

    override func tearDown() {
        super.tearDown()
        self.browser = nil
    }

    func testExecute() {
        let expectation = self.expectation(description: "JavaScript Done.")

        self.browser.open(self.startURL())
            >>> self.browser.execute("document.title")
            === { (result: JavaScriptResult?) in
                XCTAssertEqual(result, "WKZombie Test Page")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testInspect() {
        let expectation = self.expectation(description: "Inspect Done.")
        var originalPage: HTMLPage?

        self.browser.open(self.startURL())
            >>> self.browser.map { originalPage = $0 as HTMLPage }
            >>> self.browser.inspect
            === { (result: HTMLPage?) in
                if let result = result, let originalPage = originalPage {
                    XCTAssertEqual(result.data, originalPage.data)
                } else {
                    XCTAssert(false)
                }

                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testButtonPress() {
        let expectation = self.expectation(description: "Button Press Done.")

        self.browser.open(self.startURL())
            >>> self.browser.get(by: .name("button"))
            >>> self.browser.press
            >>> self.browser.execute("document.title")
            === { (result: JavaScriptResult?) in
                XCTAssertEqual(result, "WKZombie Result Page")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testFormSubmit() {
        let expectation = self.expectation(description: "Form Submit Done.")

        self.browser.open(self.startURL())
            >>> self.browser.get(by: .id("test_form"))
            >>> self.browser.submit
            >>> self.browser.execute("document.title")
            === { (result: JavaScriptResult?) in
                XCTAssertEqual(result, "WKZombie Result Page")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testFormWithXPathQuerySubmit() {
        let expectation = self.expectation(description: "Form XPathQuery Submit Done.")

        self.browser.open(self.startURL())
            >>> self.browser.get(by: .XPathQuery("//form[1]"))
            >>> self.browser.submit
            >>> self.browser.execute("document.title")
            === { (result: JavaScriptResult?) in
                XCTAssertEqual(result, "WKZombie Result Page")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testDivOnClick() {
        let expectation = self.expectation(description: "DIV OnClick Done.")

        self.browser.open(self.startURL())
            >>> self.browser.get(by: .id("onClick_div"))
            >>> self.browser.map { $0.objectForKey("onClick")! }
            >>> self.browser.execute
            >>> self.browser.inspect
            >>> self.browser.execute("document.title")
            === { (result: JavaScriptResult?) in
                XCTAssertEqual(result, "WKZombie Result Page")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testDivHref() {
        let expectation = self.expectation(description: "DIV Href Done.")

        self.browser.open(self.startURL())
            >>> self.browser.get(by: .id("href_div"))
            >>> self.browser.map { "window.location.href='\($0.objectForKey("href")!)'" }
            >>> self.browser.execute
            >>> self.browser.inspect
            >>> self.browser.execute("document.title")
            === { (result: JavaScriptResult?) in
                XCTAssertEqual(result, "WKZombie Result Page")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testUserAgent() {
        let expectation = self.expectation(description: "UserAgent Test Done.")
        self.browser.userAgent = "WKZombie"

        self.browser.open(self.startURL())
            >>> self.browser.execute("navigator.userAgent")
            === { (result: JavaScriptResult?) in
                XCTAssertEqual(result, "WKZombie")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    #if os(iOS)
    func testSnapshot() {
        let expectation = self.expectation(description: "Snapshot Test Done.")

        var snapshots = [Snapshot]()

        browser.snapshotHandler = { snapshot in
            XCTAssertNotNil(snapshot.image)
            snapshots.append(snapshot)
        }

        self.browser.open(self.startURL())
            >>> self.browser.snap
            >>> self.browser.get(by: .name("button"))
            >>> self.browser.press
            >>> self.browser.snap
            === { (_: HTMLPage?) in
                XCTAssertEqual(snapshots.count, 2)
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }
    #endif

    func testSwap() {
        let expectation = self.expectation(description: "iframe Button Test Done.")

        self.browser.open(self.startURL())
            >>> self.browser.get(by: .XPathQuery("//iframe[@name='button_frame']"))
            >>> self.browser.swap
            >>> self.browser.get(by: .XPathQuery("//button[@name='button2']"))
            >>> self.browser.press
            >>> self.browser.execute("document.title")
            === { (result: JavaScriptResult?) in
                XCTAssertEqual(result, "WKZombie Result Page")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testBasicAuthentication() {
        let expectation = self.expectation(description: "Basic Authentication Test Done.")

        self.browser.authenticationHandler = { (_) -> (URLSession.AuthChallengeDisposition, URLCredential?) in
            (.useCredential, URLCredential(user: "user", password: "passwd", persistence: .forSession))
        }

        let url = URL(string: "https://httpbin.org/basic-auth/user/passwd")!
        self.browser.open(then: .wait(2.0))(url)
            >>> self.browser.get(by: .XPathQuery("//body"))
            === { (result: HTMLElement?) in
                XCTAssertNotNil(result, "Basic Authentication Test Failed - No Body.")
                XCTAssertTrue(result!.hasChildren(), "Basic Authentication Test Failed - No JSON.")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testSelfSignedCertificates() {
        let expectation = self.expectation(description: "Self Signed Certificate Test Done.")

        self.browser.authenticationHandler = { (challenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) in
            (.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }

        let url = URL(string: "https://self-signed.badssl.com")!
        self.browser.open(then: .wait(2.0))(url)
            >>> self.browser.execute("document.title")
            === { (result: JavaScriptResult?) in
                XCTAssertEqual(result, "self-signed.badssl.com")
                expectation.fulfill()
            }

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    //========================================

    // MARK: Helper Methods

    //========================================

    private func startURL() -> URL {
        let bundle = Bundle.module
        let testPage = bundle.url(forResource: "HTMLTestPage", withExtension: "html", subdirectory: "Resources/HTML")!
        return testPage
    }
}
