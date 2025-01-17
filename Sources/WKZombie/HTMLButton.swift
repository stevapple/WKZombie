//
//  HTMLButton.swift
//  WKZombieDemo
//
//  Created by Mathias Köhnke on 06/04/16.
//  Copyright © 2016 Mathias Köhnke. All rights reserved.
//

import Foundation

/// HTML Button class, which represents the <button> element in the DOM.
public class HTMLButton: HTMLRedirectable {
    //========================================

    // MARK: Overrides

    //========================================

    internal class func createXPathQuery(_ parameters: String) -> String {
        return "//button\(parameters)"
    }
}
