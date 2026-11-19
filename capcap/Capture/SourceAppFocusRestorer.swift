import AppKit

final class SourceAppFocusRestorer {
    private let processIdentifier: pid_t?
    private var restoreScheduled = false

    private init(processIdentifier: pid_t?) {
        self.processIdentifier = processIdentifier
    }

    static func captureFrontmostApplication() -> SourceAppFocusRestorer {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let app = NSWorkspace.shared.frontmostApplication
        let targetPID = app?.processIdentifier == ownPID ? nil : app?.processIdentifier
        return SourceAppFocusRestorer(processIdentifier: targetPID)
    }

    func restore() {
        guard !restoreScheduled else { return }
        restoreScheduled = true

        DispatchQueue.main.async { [self] in
            guard
                let processIdentifier,
                let app = NSRunningApplication(processIdentifier: processIdentifier),
                !app.isTerminated,
                app.processIdentifier != ProcessInfo.processInfo.processIdentifier
            else {
                return
            }

            // Only the app's main and key windows are brought forward here.
            // Adding .activateAllWindows also drags every window of that app —
            // including windows on other displays and in other Spaces — to the
            // front, which re-stacks the whole app above whatever the user had
            // on a screen that was never captured (issue #230). Losing an
            // inactive app's side-by-side arrangement is not an acceptable
            // price for restoring focus.
            app.activate(options: [])
        }
    }
}
