//
//  ISAWebSocketDelegate.swift
//
//
//  Created by Isaías Santana on 24/04/24.
//

import Foundation

public protocol ISAWebSocketDelegate: AnyObject {
    func socketDidCloseConnection(_ socket: WebSocketClient)
    func socket(_ socket: WebSocketClient, didReceiveMessage message: SocketMessage)
    func socket(_ socket: WebSocketClient, didReceiveError error: SocketError)
    func socketDidReceivePong(_ socket: WebSocketClient)
    func socket(_ socket: WebSocketClient, pongDidFailWithError error: SocketError)
}

extension ISAWebSocketDelegate {
    public func socketDidReceivePong(_ socket: WebSocketClient) {}
    public func socket(_ socket: WebSocketClient, pongDidFailWithError error: SocketError) {}
}
