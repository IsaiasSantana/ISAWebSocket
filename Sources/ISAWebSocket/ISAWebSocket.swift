import Foundation
import Network

public final class ISAWebSocket: WebSocketClient {
    private let queue: DispatchQueue
    private let url: URL
    private var connection: NWConnection?

    public weak var delegate: ISAWebSocketDelegate?

    public init(url: URL, queue: DispatchQueue = .global(qos: .userInteractive)) {
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
            closeConnection()
        
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
        closeConnection()
    }

    public func closeConnection() {
        connection?.cancel()
        connection = nil
    }

    public func sendPing() {
        guard let connection else {
            return
        }

        guard let data = MessageContext.ping.rawValue.asData else {
            return
        }

        let metadata = NWProtocolWebSocket.Metadata(opcode: .ping)
        metadata.setPongHandler(queue) { [weak self] error in
            self?.handlePong(error: error)
        }

        let context = NWConnection.ContentContext(identifier: MessageContext.ping.rawValue)

        connection.send(content: data, contentContext: context, completion: .contentProcessed({ [weak self] error in
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

    public func send(message: SocketMessage) {
        switch message {
        case let .data(data):
            sendBinary(data)

        case let .string(text):
            sendText(text)
        }
    }

    private func sendBinary(_ data: Data) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: MessageContext.binary.rawValue)

        sendData(data, metadata: metadata, context: context)
    }

    private func sendData(_ data: Data, metadata: NWProtocolWebSocket.Metadata, context: NWConnection.ContentContext) {
        guard let connection else {
            return
        }

        connection.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed({ [weak self] error in
            if let error, let self {
                self.delegate?.socket(self, didReceiveError: .failure(error.errorCode))
            }
        }))
    }

    private func sendText(_ text: String) {
        guard let data = text.asData else {
            return
        }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: MessageContext.text.rawValue)

        sendData(data, metadata: metadata, context: context)
    }
}
