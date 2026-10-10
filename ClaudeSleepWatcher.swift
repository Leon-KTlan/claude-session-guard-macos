import AppKit
import Foundation

final class ClaudeSleepWatcher {
    private var observer: NSObjectProtocol?

    init() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: nil
        ) { _ in
            Self.stopClaudeBeforeSleep()
        }
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private static func stopClaudeBeforeSleep() {
        let guardPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/bin/claude-guard")

        guard FileManager.default.isExecutableFile(atPath: guardPath.path) else {
            return
        }

        let task = Process()
        task.executableURL = guardPath
        task.arguments = ["stop", "--reason", "system-sleep"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            let deadline = Date().addingTimeInterval(8)
            while task.isRunning && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.1)
            }
            if task.isRunning {
                task.terminate()
            }
        } catch {
            // The watcher must never block system sleep because of a stop failure.
        }
    }
}

let watcher = ClaudeSleepWatcher()
withExtendedLifetime(watcher) {
    RunLoop.main.run()
}
