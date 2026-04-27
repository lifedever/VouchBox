import Foundation
import HelperProtocol

let listener = HelperListener(machServiceName: helperMachServiceName)
listener.resume()
RunLoop.current.run()
