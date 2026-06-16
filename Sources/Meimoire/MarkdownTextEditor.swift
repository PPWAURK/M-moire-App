import AppKit
import MeimoireCore
import SwiftUI

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    let skin: MeimoireSkin
    var focusTrigger = 0
    var highlightedRanges: [NSRange] = []
    var scrollTargetLocation: Int?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, selectedRange: $selectedRange)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.string = text
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.backgroundColor = NSColor(hex: skin.palette.markdownBackground)
        textView.textColor = NSColor(hex: skin.palette.markdownText)
        textView.insertionPointColor = NSColor(hex: skin.palette.accent)
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(hex: skin.palette.selection),
            .foregroundColor: NSColor(hex: skin.palette.markdownText)
        ]
        textView.allowsUndo = true

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(hex: skin.palette.markdownBackground)
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        textView.backgroundColor = NSColor(hex: skin.palette.markdownBackground)
        textView.textColor = NSColor(hex: skin.palette.markdownText)
        textView.insertionPointColor = NSColor(hex: skin.palette.accent)
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(hex: skin.palette.selection),
            .foregroundColor: NSColor(hex: skin.palette.markdownText)
        ]
        scrollView.backgroundColor = NSColor(hex: skin.palette.markdownBackground)
        if textView.selectedRange() != selectedRange,
           selectedRange.location + selectedRange.length <= textView.string.utf16.count {
            textView.setSelectedRange(selectedRange)
        }
        context.coordinator.applyHighlights(highlightedRanges, in: textView, skin: skin)
        context.coordinator.focusIfNeeded(focusTrigger, textView: textView)
        context.coordinator.scrollIfNeeded(to: scrollTargetLocation, textView: textView)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String
        @Binding private var selectedRange: NSRange
        private var lastFocusTrigger = 0
        private var lastScrollTargetLocation: Int?
        private var appliedHighlights: [NSRange] = []

        init(text: Binding<String>, selectedRange: Binding<NSRange>) {
            _text = text
            _selectedRange = selectedRange
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            selectedRange = textView.selectedRange()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            let result: MarkdownEditResult?
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                result = MarkdownListContinuation.applyNewline(
                    to: textView.string,
                    selectedRange: textView.selectedRange()
                )
            } else if commandSelector == #selector(NSResponder.insertTab(_:)) {
                result = MarkdownListContinuation.indentListLine(
                    in: textView.string,
                    selectedRange: textView.selectedRange()
                )
            } else if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                result = MarkdownListContinuation.outdentListLine(
                    in: textView.string,
                    selectedRange: textView.selectedRange()
                )
            } else {
                return false
            }

            guard let result else { return false }
            textView.string = result.text
            textView.setSelectedRange(result.selectedRange)
            text = result.text
            selectedRange = result.selectedRange
            return true
        }

        @MainActor
        func focusIfNeeded(_ trigger: Int, textView: NSTextView) {
            guard trigger != 0, trigger != lastFocusTrigger else { return }
            lastFocusTrigger = trigger
            textView.window?.makeFirstResponder(textView)
        }

        @MainActor
        func scrollIfNeeded(to location: Int?, textView: NSTextView) {
            guard let location, location != lastScrollTargetLocation else { return }
            let safeLocation = max(0, min(location, textView.string.utf16.count))
            lastScrollTargetLocation = location
            textView.setSelectedRange(NSRange(location: safeLocation, length: 0))
            textView.scrollRangeToVisible(NSRange(location: safeLocation, length: 0))
        }

        @MainActor
        func applyHighlights(_ ranges: [NSRange], in textView: NSTextView, skin: MeimoireSkin) {
            let layoutManager = textView.layoutManager
            appliedHighlights.forEach { range in
                layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: range)
            }
            appliedHighlights = ranges.filter { range in
                range.location >= 0 && range.location + range.length <= textView.string.utf16.count
            }

            let color = NSColor(hex: skin.palette.secondaryAccent).withAlphaComponent(0.36)
            appliedHighlights.forEach { range in
                layoutManager?.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: range)
            }
        }
    }
}
