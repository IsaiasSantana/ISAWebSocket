//
//  File.swift
//  
//
//  Created by Isaías Santana on 14/04/24.
//

import Foundation

public protocol WebSocketClient {
    func startConnection()
    func closeConnection()
    func sendPing()
    func send(message: SocketMessage)
}
