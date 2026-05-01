import Foundation
import FirebaseCore

enum FirebaseBootstrap {
    static func configureIfAvailable() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}
