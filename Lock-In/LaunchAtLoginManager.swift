import Foundation
import ServiceManagement

enum LaunchAtLoginState {
    case enabled
    case disabled
    case requiresApproval
    case unsupported

    var isEnabled: Bool {
        switch self {
        case .enabled, .requiresApproval:
            return true
        case .disabled, .unsupported:
            return false
        }
    }

    var message: String? {
        switch self {
        case .requiresApproval:
            return "Startup is pending approval in System Settings > General > Login Items."
        case .unsupported:
            return "Run on startup is unavailable in this build."
        case .enabled, .disabled:
            return nil
        }
    }
}

enum LaunchAtLoginManager {
    static func currentState() -> LaunchAtLoginState {
        guard #available(macOS 13.0, *) else {
            return .unsupported
        }

        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notRegistered:
            return .disabled
        case .notFound:
            return .unsupported
        @unknown default:
            return .unsupported
        }
    }

    static func setEnabled(_ enabled: Bool) throws -> LaunchAtLoginState {
        guard #available(macOS 13.0, *) else {
            return .unsupported
        }

        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }

        return currentState()
    }
}
