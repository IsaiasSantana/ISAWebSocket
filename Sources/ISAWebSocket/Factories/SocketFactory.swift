//
//  SocketFactory.swift
//
//
//  Created by Isaías Santana on 24/04/24.
//

import Foundation
import Network

struct SocketFactory {
    static func makeConnection(url: URL, options: NWProtocolWebSocket.Options = .defaultOptions) -> NWConnection {
        let parameters = makeWebSocketParameters(url: url, options: options)

        return NWConnection(to: .url(url), using: parameters)
    }

    private static func makeWebSocketParameters(url: URL, options: NWProtocolWebSocket.Options) -> NWParameters {
        let parameters: NWParameters

        if url.scheme == .wss {
            parameters = .tls
        } else {
            parameters = .tcp
        }

        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)

        return parameters
    }
}
