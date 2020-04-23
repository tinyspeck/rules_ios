import Foundation
import MixedSourceFramework

public class DependsOnMixedSourceFramework: NSObject {
    private var logger: SwiftLogger = SwiftLogger()

    public func foo(_ message: String) {
        logger.log("Called 'foo'")
    }
}

