//
// HTMLImage.swift
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

import struct Foundation.URL
import Fuzi

/// HTML Image class, which represents the <img> element in the DOM.
public class HTMLImage: HTMLParserElement, HTMLFetchable {
    /// Returns the value of the src attribute of the image.
    public var source: String? {
        return objectForKey("src")
    }

    //========================================

    // MARK: HTMLFetchable Protocol

    //========================================

    public var fetchURL: URL? {
        if let source = source {
            return URL(string: source)
        }
        return nil
    }

    //========================================

    // MARK: Overrides

    //========================================

    internal class func createXPathQuery(_ parameters: String) -> String {
        return "//img\(parameters)"
    }
}
