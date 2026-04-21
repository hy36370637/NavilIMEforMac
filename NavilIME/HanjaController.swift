//
//  HanjaController.swift
//  NavilIME
//

import InputMethodKit
import Foundation

class HanjaController {
    static let shared = HanjaController()

    private var candidates: IMKCandidates?
    private var currentCandidates: [HanjaCandidate] = []
    private var isPreeditMode: Bool = false
    private var currentPage: Int = 0

    private init() {}

    var isReady: Bool = false

    func setup(server: IMKServer) {
        guard !isReady else { return }
        self.candidates = IMKCandidates(server: server,
                                        panelType: kIMKSingleColumnScrollingCandidatePanel)
        self.candidates?.setDismissesAutomatically(true)
        isReady = true
        PrintLog.shared.Log(log: "HanjaController: setup done (lazy)")
    }

    func hide() {
        candidates?.hide()
        currentCandidates = []
        isPreeditMode = false
        currentPage = 0
        PrintLog.shared.Log(log: "HanjaController: hidden")
    }

    var isVisible: Bool {
        return !currentCandidates.isEmpty
    }

    func handleKey(event: NSEvent) {
        if event.keyCode == 0x7D {
            let maxPage = (currentCandidates.count - 1) / 10
            if currentPage < maxPage { currentPage += 1 }
        } else if event.keyCode == 0x7E {
            if currentPage > 0 { currentPage -= 1 }
        }
        PrintLog.shared.Log(log: "HanjaController: handleKey keycode=\(event.keyCode) currentPage=\(currentPage)")
        candidates?.interpretKeyEvents([event])
    }

    func handleScalar(scalar: Unicode.Scalar, preeditMode: Bool, client: IMKTextInput) -> Bool {
        self.isPreeditMode = preeditMode
        self.currentPage = 0
        PrintLog.shared.Log(log: "HanjaController: handleScalar U+\(String(format: "%04X", scalar.value)) preeditMode=\(preeditMode)")

        let found = HanjaTable.shared.candidates(for: scalar)
        PrintLog.shared.Log(log: "HanjaController: candidates count = \(found.count)")
        guard !found.isEmpty else { return false }

        self.currentCandidates = found
        candidates?.update()
        candidates?.show(kIMKLocateCandidatesAboveHint)
        PrintLog.shared.Log(log: "HanjaController: candidates shown")
        return true
    }

    func candidatesCount() -> Int { return currentCandidates.count }

    func candidate(at index: Int) -> String {
        guard index < currentCandidates.count else { return "" }
        let c = currentCandidates[index]
        let ch = String(c.char)
        if c.meaning.isEmpty { return ch }
        return "\(ch)  \(c.meaning)"
    }

    func select(candidate: String, client: IMKTextInput) {
        guard let first = candidate.unicodeScalars.first else { return }
        let hanja = String(first)

        if isPreeditMode {
            let emptyRange = NSRange(location: NSNotFound, length: NSNotFound)
            client.setMarkedText("", selectionRange: NSRange(location: 0, length: 0), replacementRange: emptyRange)
            client.insertText(hanja, replacementRange: emptyRange)
        } else {
            let range = client.selectedRange()
            if range.location != NSNotFound && range.location > 0 {
                client.insertText(hanja, replacementRange: NSRange(location: range.location - 1, length: 1))
            } else {
                client.insertText(hanja, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
            }
        }

        currentCandidates = []
        isPreeditMode = false
        currentPage = 0
        candidates?.hide()
        PrintLog.shared.Log(log: "HanjaController: selected \(hanja)")
    }
}
