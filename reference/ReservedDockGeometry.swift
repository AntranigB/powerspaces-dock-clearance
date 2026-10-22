// Powerspaces
// Copyright © 2026 Sebastian Panman de Wit
// SPDX-License-Identifier: GPL-3.0-only

import CoreGraphics

/// Pure work-area geometry in the global, top-left-origin CG/AX coordinate space.
public enum ReservedDockGeometry {
    public enum Edge { case bottom, top, left, right }

    /// Rectangles with usable, finite point coordinates (negative origins are valid).
    public static func isValid(_ rect: CGRect) -> Bool {
        !rect.isNull && !rect.isInfinite
            && rect.origin.x.isFinite && rect.origin.y.isFinite
            && rect.size.width.isFinite && rect.size.height.isFinite
            && rect.size.width > 0 && rect.size.height > 0
            && rect.maxX.isFinite && rect.maxY.isFinite
    }

    /// Translate AppKit's visible-frame insets to the display's CG bounds.
    public static func visibleBounds(screenFrame: CGRect, visibleFrame: CGRect,
                                     displayBounds: CGRect) -> CGRect? {
        guard isValid(screenFrame), isValid(visibleFrame), isValid(displayBounds) else { return nil }
        let left = visibleFrame.minX - screenFrame.minX
        let right = screenFrame.maxX - visibleFrame.maxX
        let bottom = visibleFrame.minY - screenFrame.minY
        let top = screenFrame.maxY - visibleFrame.maxY
        let insets = [left, right, bottom, top]
        guard insets.allSatisfy({ $0.isFinite && $0 >= -0.5 }),
              left + right < displayBounds.width,
              top + bottom < displayBounds.height else { return nil }
        let bounds = CGRect(x: displayBounds.minX + max(0, left),
                            y: displayBounds.minY + max(0, top),
                            width: displayBounds.width - max(0, left) - max(0, right),
                            height: displayBounds.height - max(0, top) - max(0, bottom))
        return isValid(bounds) ? bounds : nil
    }

    /// Reserve a full edge of the native visible area for Powerspaces' visible Dock.
    public static func usableBounds(from bounds: CGRect, reserving edge: Edge,
                                    depth: CGFloat) -> CGRect? {
        guard isValid(bounds), depth.isFinite, depth >= 0 else { return nil }
        var usable = bounds
        switch edge {
        case .bottom: usable.size.height -= depth
        case .top:
            usable.origin.y += depth
            usable.size.height -= depth
        case .left:
            usable.origin.x += depth
            usable.size.width -= depth
        case .right: usable.size.width -= depth
        }
        return isValid(usable) ? usable : nil
    }

    /// The smallest move/resize that fits the window, or nil if already clear.
    public static func constrain(window: CGRect, into usableBounds: CGRect) -> CGRect? {
        guard isValid(window), isValid(usableBounds) else { return nil }
        let width = min(window.width, usableBounds.width)
        let height = min(window.height, usableBounds.height)
        let x = min(max(window.minX, usableBounds.minX), usableBounds.maxX - width)
        let y = min(max(window.minY, usableBounds.minY), usableBounds.maxY - height)
        let corrected = CGRect(x: x, y: y, width: width, height: height)
        guard isValid(corrected) else { return nil }
        let differences = [corrected.minX - window.minX, corrected.minY - window.minY,
                           corrected.maxX - window.maxX, corrected.maxY - window.maxY,
                           corrected.width - window.width, corrected.height - window.height]
        return differences.allSatisfy { abs($0) <= 0.5 } ? nil : corrected
    }
}
