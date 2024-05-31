import Network

public enum PingPongStatus {
    case failedPing(NWError)
    case failedPong(NWError)
    case receivedPong
}
