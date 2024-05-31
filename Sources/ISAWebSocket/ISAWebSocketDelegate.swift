//
//  ISAWebSocketDelegate.swift
//
//
//  Created by Isaías Santana on 24/04/24.
//

import Foundation
import Network

public protocol ISAWebSocketDelegate: AnyObject {
    func socket(_ socket: WebSocketClient, didReceiveConnectionStatus status: ConnectionStatus)
    func socket(_ socket: WebSocketClient, didReceiveMessage message: Result<SocketMessage, NWError>)
    func socket(_ socket: WebSocketClient, sendMessageDidFailedWithError error: NWError)
    func socket(_ socket: WebSocketClient, didReceivePingPongStatus status: PingPongStatus)
}
