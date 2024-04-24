//
//  File.swift
//  
//
//  Created by Isaías Santana on 24/04/24.
//

import Foundation

extension String {
    static let ws = "ws"
    static let wss = "wss"
    
    var asData: Data? {
        data(using: .utf8)
    }
}
