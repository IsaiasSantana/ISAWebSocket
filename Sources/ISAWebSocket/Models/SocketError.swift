//
//  SocketError.swift
//
//
//  Created by Isaías Santana on 18/04/24.
//

import Foundation

public enum SocketError: Error {
    case connectionCancelled
    case failure(Int)
    case malformedURL
    case failureToStartConnection
}
