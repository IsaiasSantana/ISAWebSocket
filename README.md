# ISAWebSocket

Simple WebSocket client on top of the Network framework

## Usage

```swift
let socket = ISAWebSocket(url: URL(string: "wss://socketurl")!)

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

    func socket(_ socket: WebSocketClient, didReceiveConnectionStatus status: ConnectionStatus) {
        
    }

    func socket(_ socket: WebSocketClient, didReceiveMessage message: Result<SocketMessage, NWError>) {
        
    }

    func socket(_ socket: WebSocketClient, sendMessageDidFailedWithError error: NWError) {
        
    }

    func socket(_ socket: WebSocketClient, didReceivePingPongStatus status: PingPongStatus) {
       
    }
}

```

## Close connection
```swift
socket.closeConnection()
```

## Send data

```swift
socket.send(message: .string("some_UTF8_String"))

socket.send(message: .data(Data()))
```

## Send ping
```swift
socket.sendPing()
```

## Example
https://github.com/IsaiasSantana/ISAWebSocketExample
