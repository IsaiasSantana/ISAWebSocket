import Foundation
import Network

public protocol ISAWebSocketDelegate: AnyObject {
    func socketDidCloseConnection(_ socket: WebSocketClient)
    func socket(_ socket: WebSocketClient, didReceiveMessage message: SocketMessage)
    func socket(_ socket: WebSocketClient, didReceiveError error: SocketError)
    func socketDidFailToStartConnection(_ socket: WebSocketClient)
}

extension String {
    static let ws = "ws"
    static let wss = "wss"
}

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
    
    private func handleFailedConnection(_ error: NWError) {
        delegate?.socket(self, didReceiveError: .failure(error.errorCode))
        connection?.cancel()
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
    
    public func sendPing(pongHandler: ((Error?) -> Void)? = nil) {
        
    }
}
