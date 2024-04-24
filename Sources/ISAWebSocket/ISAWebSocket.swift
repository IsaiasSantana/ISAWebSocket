import Foundation
import Network

public protocol ISAWebSocketDelegate: AnyObject {
    func socketDidCloseConnection(_ socket: WebSocketClient)
    func socket(_ socket: WebSocketClient, didReceiveMessage message: SocketMessage)
    func socket(_ socket: WebSocketClient, didReceiveError error: SocketError)
    func socketDidReceivePong(_ socket: WebSocketClient)
    func socket(_ socket: WebSocketClient, pongDidFailWithError error: SocketError)
    func socketDidFailToStartConnection(_ socket: WebSocketClient)
}

public final class ISAWebSocket: WebSocketClient {
    private let queue: DispatchQueue
    private let url: URL
    private var connection: NWConnection?

    public weak var delegate: ISAWebSocketDelegate?
    
    init(url: URL, queue: DispatchQueue = .global(qos: .userInteractive)) {
        self.url = url
        self.queue = queue
        connection = SocketFactory.makeConnection(url: url)
    }

    public func startConnection() {
        if let connection, connection.state != .ready {
            setupConnectionHandlers()
            connection.start(queue: queue)
            return
        }

        if connection == nil {
            connection = SocketFactory.makeConnection(url: url)
            setupConnectionHandlers()
            connection?.start(queue: queue)
        }
    }
    
    private func setupConnectionHandlers() {
        guard let connection else {
            return
        }
        
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleState(state)
        }
    }
    
    private func handleState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            receiveMessage()
            
        case .failed(let error):
            handleFailedConnection(error)
            
        case .cancelled:
            delegate?.socket(self, didReceiveError: .connectionCancelled)
        
        default:
            break
        }
    }
    
    private func receiveMessage() {
        guard let connection else {
            return
        }

        connection.receiveMessage { [weak self] (data, context, _, error) in
            if let error, let self {
                delegate?.socket(self, didReceiveError: .failure(error.errorCode))
                return
            }
            
            self?.handleMessage(data: data, context: context)
            
            self?.receiveMessage()
        }
    }
    
    private func handleMessage(data: Data?, context: NWConnection.ContentContext?) {
        guard let data else {
            return
        }

        guard let metadata = context?.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata else {
            return
        }
 
        switch metadata.opcode {
        case .text:
            handleText(from: data)
            
        case .binary:
            delegate?.socket(self, didReceiveMessage: .data(data))
            
        case .close:
            delegate?.socketDidCloseConnection(self)
            
        default:
            break
        }
    }
    
    private func handleText(from data: Data) {
        if let message = String(data: data, encoding: .utf8) {
            delegate?.socket(self, didReceiveMessage: .string(message))
        }
    }
    
    private func handleFailedConnection(_ error: NWError) {
        delegate?.socket(self, didReceiveError: .failure(error.errorCode))
        connection?.cancel()
    }

    public func sendPing() {
        guard let data = MessageContext.ping.rawValue.asData else {
            return
        }

        let metadata = NWProtocolWebSocket.Metadata(opcode: .ping)
        metadata.setPongHandler(queue) { [weak self] error in
            self?.handlePong(error: error)
        }

        let context = NWConnection.ContentContext(identifier: MessageContext.ping.rawValue)
        
        connection?.send(content: data, contentContext: context, completion: .contentProcessed({ [weak self] error in
            self?.handleSendPing(error: error)
        }))
    }

    private func handlePong(error: NWError?) {
        if let error {
            delegate?.socket(self, pongDidFailWithError: .failure(error.errorCode))
            return
        }

        delegate?.socketDidReceivePong(self)
    }

    private func handleSendPing(error: NWError?) {
        if error != nil {
            delegate?.socket(self, didReceiveError: .failureSendPing)
            return
        }
    }
}
