//
//  HanjaTable.swift
//  NavilIME
//
//  Created by HY on 21/4/26
//  hanja.json 을 런타임에 로드하여 한자/기호 후보 목록을 제공
//

import Foundation

struct HanjaCandidate {
    let char: Unicode.Scalar
    let meaning: String
}

// JSON 디코딩용 구조체
private struct HanjaCandidateJSON: Decodable {
    let c: Int
    let m: String
}

class HanjaTable {
    static let shared = HanjaTable()
    private var table: [Unicode.Scalar: [HanjaCandidate]] = [:]

    private init() {
        loadJSON()
    }

    func candidates(for scalar: Unicode.Scalar) -> [HanjaCandidate] {
        return table[scalar] ?? []
    }

    private func loadJSON() {
        guard let url = Bundle.main.url(forResource: "hanja", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            PrintLog.shared.Log(log: "HanjaTable: hanja.json not found")
            return
        }

        guard let raw = try? JSONDecoder().decode([String: [HanjaCandidateJSON]].self, from: data) else {
            PrintLog.shared.Log(log: "HanjaTable: JSON decode failed")
            return
        }

        for (keyStr, candidates) in raw {
            guard let keyInt = UInt32(keyStr),
                  let keyScalar = Unicode.Scalar(keyInt) else { continue }

            let parsed: [HanjaCandidate] = candidates.compactMap { item in
                guard let scalar = Unicode.Scalar(UInt32(item.c)) else { return nil }
                return HanjaCandidate(char: scalar, meaning: item.m)
            }
            if !parsed.isEmpty {
                table[keyScalar] = parsed
            }
        }
        PrintLog.shared.Log(log: "HanjaTable: loaded \(table.count) entries")
    }
}