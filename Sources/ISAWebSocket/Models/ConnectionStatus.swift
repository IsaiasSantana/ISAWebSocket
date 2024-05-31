import Foundation
import Network

public enum ConnectionStatus {
    case closed
    case cancelled
    case failed(NWError)
}
