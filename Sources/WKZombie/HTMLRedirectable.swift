//
//  HTMLRedirectable.swift
//  WKZombieDemo
//
//  Created by Mathias Köhnke on 06/04/16.
//  Copyright © 2016 Mathias Köhnke. All rights reserved.
//

import Foundation

/// Base class for redirectable HTML elements (e.g. HTMLLink, HTMLButton).
public class HTMLRedirectable: HTMLParserElement {
    //========================================

    // MARK: Link Redirectable Script

    //========================================

    internal func actionScript() -> String? {
        if let onClick = objectForKey("onclick") {
            return onClick
        }
        return nil
    }
}
