//
//  File.swift
//  
//
//  Created by Isaías Santana on 30/05/24.
//

import Foundation
import Network

extension NWProtocolWebSocket.Options {
    public static var defaultOptions: NWProtocolWebSocket.Options {
        let options = NWProtocolWebSocket.Options()
        options.autoReplyPing = true
        return options
    }
}
