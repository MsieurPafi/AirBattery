//
//  WindowAccessor.swift
//  xHistory
//
//  Created by apple on 2024/11/7.
//

import AppKit
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    var onWindowOpen: ((NSWindow?) -> Void)?
    var onWindowActive: ((NSWindow?) -> Void)?
    var onWindowDeactivate: ((NSWindow?) -> Void)?
    var onWindowClose: (() -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                // Observe the window instead of becoming its delegate: SwiftUI manages its own
                // windows (Settings) through their delegate, and replacing it left the Settings
                // window blank once closed and reopened.
                context.coordinator.observe(window)
                self.onWindowOpen?(window)
            } else {
                self.onWindowOpen?(nil)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onWindowOpen: onWindowOpen,
            onWindowActive: onWindowActive,
            onWindowDeactivate: onWindowDeactivate,
            onWindowClose: onWindowClose
        )
    }

    class Coordinator: NSObject {
        weak var window: NSWindow? // 使用 weak 避免循环引用
        var onWindowOpen: ((NSWindow?) -> Void)?
        var onWindowActive: ((NSWindow?) -> Void)?
        var onWindowDeactivate: ((NSWindow?) -> Void)?
        var onWindowClose: (() -> Void)?

        init(onWindowOpen: ((NSWindow?) -> Void)? = nil,
             onWindowActive: ((NSWindow?) -> Void)? = nil,
             onWindowDeactivate: ((NSWindow?) -> Void)? = nil,
             onWindowClose: (() -> Void)? = nil) {
            self.onWindowOpen = onWindowOpen
            self.onWindowClose = onWindowClose
            self.onWindowActive = onWindowActive
            self.onWindowDeactivate = onWindowDeactivate
        }

        private var observers: [NSObjectProtocol] = []

        func observe(_ window: NSWindow) {
            guard self.window !== window else { return }
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            self.window = window
            let center = NotificationCenter.default
            observers = [
                center.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in self?.onWindowClose?() },
                center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] _ in self?.onWindowActive?(self?.window) },
                center.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in self?.onWindowDeactivate?(self?.window) },
            ]
        }

        deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }
    }
}
