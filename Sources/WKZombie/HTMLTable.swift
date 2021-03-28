//
// HTMLTable.swift
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

/// HTML Table class, which represents the "table" element in the DOM.
public class HTMLTable : HTMLParserElement {
    
    /// Returns all row elements within this table
    public var rows : [HTMLTableRow]? {
        let rows : [HTMLTableRow]? = children(as: HTMLTableRow.self)
        if let row = rows?.first,
           row.tagName == "tbody" {
            return row.children(as: HTMLTableRow.self)
        } else {
            return rows
        }
    }
        
    //========================================
    // MARK: Overrides
    //========================================

    internal class func createXPathQuery(_ parameters: String) -> String {
        return "//table\(parameters)"
    }
}


/// HTML Table Row Class, which represents the <tr> element in the DOM.
public class HTMLTableRow : HTMLParserElement {
    
    /// Returns all columns within this row.
    public var columns : [HTMLTableColumn]? {
        return children(as: HTMLTableColumn.self)
    }
    
    //========================================
    // MARK: Overrides
    //========================================
    
    internal class func createXPathQuery(_ parameters: String) -> String {
        return "//tr\(parameters)"
    }
}

/// HTML Table Column class, which represents the <td> element in the DOM.
public class HTMLTableColumn : HTMLParserElement {
    
    //========================================
    // MARK: Overrides
    //========================================
    
    internal class func createXPathQuery(_ parameters: String) -> String {
        return "//td\(parameters)"
    }
}
