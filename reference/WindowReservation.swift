// Powerspaces
// Copyright © 2026 Sebastian Panman de Wit
// SPDX-License-Identifier: GPL-3.0-only

import AppKit
import CoreGraphics

/// Conservatively corrects ordinary visible windows through Accessibility.
public enum WindowReservation {
    public struct Area {
        public let displayBounds: CGRect
        public let usableBounds: CGRect

        public init(displayBounds: CGRect, usableBounds: CGRect) {
            self.displayBounds = displayBounds
            self.usableBounds = usableBounds
        }
    }

    /// A point on the shared edge of two displays belongs to just one of them.
    private static func owns(_ point: CGPoint, on display: CGRect) -> Bool {
        point.x >= display.minX && point.x < display.maxX
            && point.y >= display.minY && point.y < display.maxY
    }

    private static func isValid(_ area: Area) -> Bool {
        let d = area.displayBounds
        let u = area.usableBounds
        return ReservedDockGeometry.isValid(d) && ReservedDockGeometry.isValid(u)
            && u.minX >= d.minX && u.maxX <= d.maxX
            && u.minY >= d.minY && u.maxY <= d.maxY
    }

    /// Cheap snapshot filter. It performs no Accessibility calls.
    public static func isCandidate(_ window: WindowInfo, displayBounds: CGRect,
                                   usableBounds: CGRect, excludingPID: pid_t?) -> Bool {
        let area = Area(displayBounds: displayBounds, usableBounds: usableBounds)
        guard isValid(area), window.pid > 0, window.windowID != 0,
              window.pid != excludingPID, window.isOnscreen,
              !window.isMinimized, !window.isHidden,
              ReservedDockGeometry.isValid(window.bounds),
              owns(window.center, on: displayBounds) else { return false }
        return ReservedDockGeometry.constrain(window: window.bounds, into: usableBounds) != nil
    }

    /// More restrictive than the Dock's window filter: utility windows may appear
    /// in the Dock, but must never be repositioned as normal application windows.
    public static func isOrdinaryWindow(role: String?, subrole: String?, isModal: Bool) -> Bool {
        WindowFilter.isStandaloneWindow(role: role, subrole: subrole, isModal: isModal)
            && subrole == "AXStandardWindow"
    }

    /// Fetch each candidate app's AX window list once across all eligible displays.
    public static func enforce(windows: [WindowInfo], areas: [Area], excludingPID: pid_t?) {
        guard !areas.isEmpty else { return }
        var byPID: [pid_t: [(window: WindowInfo, area: Area)]] = [:]
        var seen: Set<CGWindowID> = []
        for window in windows {
            guard !seen.contains(window.windowID),
                  let area = areas.first(where: {
                      isCandidate(window, displayBounds: $0.displayBounds,
                                  usableBounds: $0.usableBounds, excludingPID: excludingPID)
                  }) else { continue }
            seen.insert(window.windowID)
            byPID[window.pid, default: []].append((window, area))
        }
        guard !byPID.isEmpty, WindowAX.isTrusted else { return }

        for (pid, candidates) in byPID {
            guard let app = NSRunningApplication(processIdentifier: pid),
                  app.activationPolicy == .regular, !app.isHidden, !app.isTerminated else { continue }
            let axWindows = WindowAX.windows(of: pid)
            for (candidate, area) in candidates {
                guard let ax = WindowAX.firstWindow(windowID: candidate.windowID, in: axWindows),
                      isOrdinaryWindow(role: WindowAX.role(of: ax),
                                       subrole: WindowAX.subrole(of: ax),
                                       isModal: WindowAX.isModal(ax)),
                      WindowAX.minimizedState(of: ax) == false, !WindowAX.isFullscreen(ax),
                      let live = WindowAX.frame(of: ax),
                      ReservedDockGeometry.isValid(live),
                      owns(CGPoint(x: live.midX, y: live.midY), on: area.displayBounds),
                      let corrected = ReservedDockGeometry.constrain(window: live, into: area.usableBounds)
                else { continue }
                _ = WindowAX.setFrame(corrected, of: ax, from: live)
            }
        }
    }
}
