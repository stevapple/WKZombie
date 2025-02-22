//
// HTMLForm.swift
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

import Fuzi

/// HTML Form class, which represents the <form> element in the DOM.
public class HTMLForm: HTMLParserElement {
    /// All inputs fields (keys and values) of this form.
    public fileprivate(set) var inputElements = [String: String]()

    public required convenience init(element: XMLElement) {
        self.init(element: element, XPathQuery: nil)
    }

    public required init(element: XMLElement, XPathQuery: String?) {
        super.init(element: element, XPathQuery: XPathQuery)
        self.retrieveAllInputs(HTMLParserElement(element: element, XPathQuery: XPathQuery))
    }

    /// Returns the value for the name attribute.
    public var name: String? {
        return objectForKey("name")
    }

    /// Returns the value for the id attribute.
    public var id: String? {
        return objectForKey("id")
    }

    /// Returns the value for the action attribute.
    public var action: String? {
        return objectForKey("action")
    }

    /**
     Enables subscripting for modifying the input field values.

     - parameter input: The Input field attribute name.

     - returns: The Input field attribute value.
     */
    public subscript(key: String) -> String? {
        return self.inputElements[key]
    }

    //========================================

    // MARK: Form Submit Script

    //========================================

    internal func actionScript() -> String? {
        if let name = name {
            return "document.\(name).submit();"
        } else if let id = id {
            return "document.getElementById('\(id)').submit();"
        }
        return nil
    }

    //========================================

    // MARK: Overrides

    //========================================

    internal class func createXPathQuery(_ parameters: String) -> String {
        return "//form\(parameters)"
    }

    //========================================

    // MARK: Private Methods

    //========================================

    fileprivate func retrieveAllInputs(_ element: HTMLElement) {
        if let tagName = element.tagName, tagName == "input" {
            if let name = element.objectForKey("name") {
                self.inputElements[name] = element.objectForKey("value")
            }
        }
        if let children = element.children(), children.count > 0 {
            for child in children {
                self.retrieveAllInputs(child)
            }
        }
    }
}
