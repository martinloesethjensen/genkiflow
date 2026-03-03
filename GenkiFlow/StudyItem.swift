import Foundation
import SwiftData

// MARK: - Reading Object

struct ReadingObject: Codable, Hashable {
    let value: String
    let type: String // "on", "kun", or "vocab"
}

// MARK: - Study Item Model

@Model
final class StudyItem {
    #Index<StudyItem>([\.srsStage], [\.nextReview], [\.type], [\.srsStage, \.nextReview])

    /// Builds a single searchable string from the item's fields.
    static func buildSearchableText(
        subject: String,
        furigana: String,
        meanings: [String],
        readings: [ReadingObject]
    ) -> String {
        var parts = [subject.lowercased(), furigana.lowercased()]
        parts.append(contentsOf: meanings.map { $0.lowercased() })
        for reading in readings {
            let val = reading.value.lowercased()
            parts.append(val)
            // Add romaji version of each reading
            let romaji = RomajiConverter.kanaToRomaji(val)
            if romaji != val {
                parts.append(romaji)
            }
        }
        // Also add romaji of furigana if present
        if !furigana.isEmpty {
            let romajiF = RomajiConverter.kanaToRomaji(furigana.lowercased())
            if romajiF != furigana.lowercased() {
                parts.append(romajiF)
            }
        }
        return parts.joined(separator: " ")
    }

    @Attribute(.unique) var id: String
    var type: String
    var subject: String
    var furigana: String
    var meanings: [String]
    var readings: [ReadingObject]
    var srsStage: Int
    var nextReview: Date
    var lastIncorrectDate: Date?

    /// Precomputed lowercase text combining subject, furigana, meanings, readings, and romaji for fast search.
    var searchableText: String

    init(
        id: String,
        type: String,
        subject: String,
        furigana: String,
        meanings: [String],
        readings: [ReadingObject],
        srsStage: Int = 0,
        nextReview: Date = .now,
        lastIncorrectDate: Date? = nil,
        searchableText: String = ""
    ) {
        self.id = id
        self.type = type
        self.subject = subject
        self.furigana = furigana
        self.meanings = meanings
        self.readings = readings
        self.srsStage = srsStage
        self.nextReview = nextReview
        self.lastIncorrectDate = lastIncorrectDate
        self.searchableText = searchableText
    }
}

// MARK: - JSON Decoding DTOs

struct StudyItemDTO: Decodable {
    let id: String
    let type: String
    let subject: String
    let furigana: String
    let meanings: [String]
    let readings: [ReadingDTO]

    enum ReadingDTO: Decodable {
        case string(String)
        case object(ReadingObject)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                self = .string(str)
            } else {
                self = .object(try container.decode(ReadingObject.self))
            }
        }
    }

    func toReadingObjects() -> [ReadingObject] {
        readings.map { dto in
            switch dto {
            case .string(let value):
                return ReadingObject(value: value, type: "vocab")
            case .object(let obj):
                return obj
            }
        }
    }
}
