# ISAWebSocket

Simple WebSocket client on top of the Network framework

## Usage

```swift
let queue = DispatchQueue.global(qos: .userInitiated)
let socket = ISAWebSocket(url: URL(string: "wss://socketurl")!, queue: queue)

socket.delegate = MyDelegate()

socket.startConnection()

.....

final class MyDelegate: ISAWebSocketDelegate {
    func socket(_ socket: WebSocketClient, didReceiveMessage message: SocketMessage) {
        handle(message: message)
    }

    private func handle(message: SocketMessage) {
        switch message {
        case let .string(text):
            break

        case let .data(data):
            break
        }
    }

    func socketDidCloseConnection(_ socket: WebSocketClient) {

    }
    
    func socket(_ socket: WebSocketClient, didReceiveError error: SocketError) {

    }

    func socketDidReceivePong(_ socket: WebSocketClient) {

    }

    func socket(_ socket: WebSocketClient, pongDidFailWithError error: SocketError) {

    }
}


socket.closeConnection()
```

## TODO

- [ ] SSL Pinning
