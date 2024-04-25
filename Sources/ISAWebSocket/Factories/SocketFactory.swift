//
//  SocketFactory.swift
//
//
//  Created by Isaías Santana on 24/04/24.
//

import Foundation
import Network

struct SocketFactory {
    static func makeConnection(url: URL) -> NWConnection {
        let parameters = makeWebSocketParameters(url: url)

        return NWConnection(to: .url(url), using: parameters)
    }

    private static func makeWebSocketParameters(url: URL) -> NWParameters {
        let parameters: NWParameters
        let options = NWProtocolWebSocket.Options()
        options.autoReplyPing = true
        
        if url.scheme == .wss {
            parameters = .tls
        } else {
            parameters = .tcp
        }

        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)

        return parameters
    }
}
