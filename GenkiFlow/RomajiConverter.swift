import Foundation

/// Converts romaji text to hiragana and katakana for answer matching.
enum RomajiConverter {

    // MARK: - Public

    /// Converts a romaji string to hiragana.
    static func toHiragana(_ input: String) -> String {
        convert(input.lowercased(), table: romajiToHiragana)
    }

    /// Converts a romaji string to katakana.
    static func toKatakana(_ input: String) -> String {
        convert(input.lowercased(), table: romajiToKatakana)
    }

    // MARK: - Conversion Engine

    private static func convert(_ input: String, table: [String: String]) -> String {
        var result = ""
        var i = input.startIndex

        while i < input.endIndex {
            let current = input[i]

            // Handle "n" before a consonant or at end of string → ん/ン
            if current == "n" {
                let nextIndex = input.index(after: i)
                if nextIndex == input.endIndex {
                    // "n" at end of input
                    result += table["nn"] ?? "n"
                    i = nextIndex
                    continue
                }
                let next = input[nextIndex]
                // "n" followed by a consonant that isn't "y" or another "n",
                // and isn't a vowel → it's ん
                if next.isLetter && !"aiueony".contains(next) {
                    result += table["nn"] ?? "n"
                    i = nextIndex
                    continue
                }
            }

            // Handle double consonants (っ/ッ): e.g. "kk" in "kekka"
            // Exclude "n" — "nn" is handled by the table as ん
            if i < input.index(before: input.endIndex) {
                let next = input[input.index(after: i)]
                if current == next && current != "n" && !"aiueo".contains(current) && current.isLetter {
                    result += table["xtu"] ?? String(current)
                    i = input.index(after: i)
                    continue
                }
            }

            // Try 4-char, 3-char, 2-char, then 1-char matches
            var matched = false
            for length in stride(from: 4, through: 1, by: -1) {
                guard let end = input.index(i, offsetBy: length, limitedBy: input.endIndex) else {
                    continue
                }
                let chunk = String(input[i..<end])
                if let kana = table[chunk] {
                    result += kana
                    i = end
                    matched = true
                    break
                }
            }

            if !matched {
                result += String(input[i])
                i = input.index(after: i)
            }
        }

        return result
    }

    // MARK: - Mapping Tables

    private static let romajiToHiragana: [String: String] = {
        var map: [String: String] = [
            // Vowels
            "a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",

            // K-row
            "ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
            // G-row
            "ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",

            // S-row
            "sa": "さ", "si": "し", "shi": "し", "su": "す", "se": "せ", "so": "そ",
            // Z-row
            "za": "ざ", "zi": "じ", "ji": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",

            // T-row
            "ta": "た", "ti": "ち", "chi": "ち", "tu": "つ", "tsu": "つ", "te": "て", "to": "と",
            // D-row
            "da": "だ", "di": "ぢ", "du": "づ", "dzu": "づ", "de": "で", "do": "ど",

            // N-row
            "na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",

            // H-row
            "ha": "は", "hi": "ひ", "hu": "ふ", "fu": "ふ", "he": "へ", "ho": "ほ",
            // B-row
            "ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",
            // P-row
            "pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",

            // M-row
            "ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",

            // Y-row
            "ya": "や", "yu": "ゆ", "yo": "よ",

            // R-row
            "ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",

            // W-row
            "wa": "わ", "wi": "ゐ", "we": "ゑ", "wo": "を",

            // N (standalone)
            "nn": "ん", "n'": "ん", "xn": "ん",

            // Small kana
            "xa": "ぁ", "xi": "ぃ", "xu": "ぅ", "xe": "ぇ", "xo": "ぉ",
            "xya": "ゃ", "xyu": "ゅ", "xyo": "ょ",
            "xtu": "っ", "xtsu": "っ",

            // Combo: ky
            "kya": "きゃ", "kyi": "きぃ", "kyu": "きゅ", "kye": "きぇ", "kyo": "きょ",
            // Combo: gy
            "gya": "ぎゃ", "gyi": "ぎぃ", "gyu": "ぎゅ", "gye": "ぎぇ", "gyo": "ぎょ",

            // Combo: sh ("shi" already in S-row above)
            "sha": "しゃ", "shu": "しゅ", "she": "しぇ", "sho": "しょ",
            // Combo: sy
            "sya": "しゃ", "syi": "しぃ", "syu": "しゅ", "sye": "しぇ", "syo": "しょ",

            // Combo: j
            "ja": "じゃ", "ju": "じゅ", "je": "じぇ", "jo": "じょ",
            // Combo: jy / zy
            "jya": "じゃ", "jyu": "じゅ", "jyo": "じょ",
            "zya": "じゃ", "zyu": "じゅ", "zyo": "じょ",

            // Combo: ch
            "cha": "ちゃ", "chu": "ちゅ", "che": "ちぇ", "cho": "ちょ",
            // Combo: ty
            "tya": "ちゃ", "tyi": "ちぃ", "tyu": "ちゅ", "tye": "ちぇ", "tyo": "ちょ",

            // Combo: dy
            "dya": "ぢゃ", "dyi": "ぢぃ", "dyu": "ぢゅ", "dye": "ぢぇ", "dyo": "ぢょ",

            // Combo: ny
            "nya": "にゃ", "nyi": "にぃ", "nyu": "にゅ", "nye": "にぇ", "nyo": "にょ",

            // Combo: hy
            "hya": "ひゃ", "hyi": "ひぃ", "hyu": "ひゅ", "hye": "ひぇ", "hyo": "ひょ",

            // Combo: by
            "bya": "びゃ", "byi": "びぃ", "byu": "びゅ", "bye": "びぇ", "byo": "びょ",

            // Combo: py
            "pya": "ぴゃ", "pyi": "ぴぃ", "pyu": "ぴゅ", "pye": "ぴぇ", "pyo": "ぴょ",

            // Combo: my
            "mya": "みゃ", "myi": "みぃ", "myu": "みゅ", "mye": "みぇ", "myo": "みょ",

            // Combo: ry
            "rya": "りゃ", "ryi": "りぃ", "ryu": "りゅ", "rye": "りぇ", "ryo": "りょ",

            // Long vowel mark
            "-": "ー",
        ]
        return map
    }()

    private static let romajiToKatakana: [String: String] = {
        // Build katakana table by converting each hiragana value
        var map: [String: String] = [:]
        for (key, hiragana) in romajiToHiragana {
            map[key] = hiraganaToKatakana(hiragana)
        }
        return map
    }()

    /// Converts a kana string (hiragana or katakana) to romaji.
    static func kanaToRomaji(_ input: String) -> String {
        // Normalize: convert katakana to hiragana first
        let hiragana = katakanaToHiragana(input)
        var result = ""
        var i = hiragana.startIndex

        while i < hiragana.endIndex {
            // Try 2-char match first (combo kana like きゃ)
            if let nextIndex = hiragana.index(i, offsetBy: 2, limitedBy: hiragana.endIndex),
               let romaji = hiraganaToRomajiMap[String(hiragana[i..<nextIndex])] {
                result += romaji
                i = nextIndex
                continue
            }

            let ch = String(hiragana[i])

            // っ (small tsu) → double the next consonant
            if ch == "っ" {
                let nextIndex = hiragana.index(after: i)
                if nextIndex < hiragana.endIndex {
                    // Look ahead to find what consonant to double
                    var lookAhead = ""
                    if let twoAhead = hiragana.index(nextIndex, offsetBy: 2, limitedBy: hiragana.endIndex),
                       let rom = hiraganaToRomajiMap[String(hiragana[nextIndex..<twoAhead])] {
                        lookAhead = rom
                    } else if let rom = hiraganaToRomajiMap[String(hiragana[nextIndex])] {
                        lookAhead = rom
                    }
                    if let firstConsonant = lookAhead.first, !"aiueo".contains(firstConsonant) {
                        result += String(firstConsonant)
                    } else {
                        result += "t" // fallback
                    }
                }
                i = hiragana.index(after: i)
                continue
            }

            // Single char lookup
            if let romaji = hiraganaToRomajiMap[ch] {
                result += romaji
            } else {
                result += ch // pass through unknown chars
            }
            i = hiragana.index(after: i)
        }

        return result
    }

    // MARK: - Kana → Romaji Table

    private static let hiraganaToRomajiMap: [String: String] = [
        // Vowels
        "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
        // K
        "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
        // G
        "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
        // S
        "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
        // Z
        "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
        // T
        "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
        // D
        "だ": "da", "ぢ": "di", "づ": "du", "で": "de", "ど": "do",
        // N
        "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
        // H
        "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
        // B
        "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
        // P
        "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
        // M
        "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
        // Y
        "や": "ya", "ゆ": "yu", "よ": "yo",
        // R
        "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
        // W
        "わ": "wa", "ゐ": "wi", "ゑ": "we", "を": "wo",
        // N
        "ん": "n",
        // Combos (2-char hiragana → romaji)
        "きゃ": "kya", "きゅ": "kyu", "きょ": "kyo",
        "ぎゃ": "gya", "ぎゅ": "gyu", "ぎょ": "gyo",
        "しゃ": "sha", "しゅ": "shu", "しょ": "sho",
        "じゃ": "ja", "じゅ": "ju", "じょ": "jo",
        "ちゃ": "cha", "ちゅ": "chu", "ちょ": "cho",
        "ぢゃ": "dya", "ぢゅ": "dyu", "ぢょ": "dyo",
        "にゃ": "nya", "にゅ": "nyu", "にょ": "nyo",
        "ひゃ": "hya", "ひゅ": "hyu", "ひょ": "hyo",
        "びゃ": "bya", "びゅ": "byu", "びょ": "byo",
        "ぴゃ": "pya", "ぴゅ": "pyu", "ぴょ": "pyo",
        "みゃ": "mya", "みゅ": "myu", "みょ": "myo",
        "りゃ": "rya", "りゅ": "ryu", "りょ": "ryo",
        // Long vowel
        "ー": "-",
    ]

    // MARK: - Helpers

    private static func katakanaToHiragana(_ str: String) -> String {
        String(str.unicodeScalars.map { scalar in
            // Katakana range: U+30A1 to U+30F6 → Hiragana: U+3041 to U+3096
            if scalar.value >= 0x30A1 && scalar.value <= 0x30F6 {
                return Character(UnicodeScalar(scalar.value - 0x60)!)
            }
            return Character(scalar)
        })
    }

    private static func hiraganaToKatakana(_ str: String) -> String {
        String(str.unicodeScalars.map { scalar in
            // Hiragana range: U+3041 to U+3096
            // Katakana range: U+30A1 to U+30F6 (offset +0x60)
            if scalar.value >= 0x3041 && scalar.value <= 0x3096 {
                return Character(UnicodeScalar(scalar.value + 0x60)!)
            }
            // Keep prolonged sound mark and other characters as-is
            return Character(scalar)
        })
    }
}
