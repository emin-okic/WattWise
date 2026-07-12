import Foundation
import SwiftData

@Model
final class UsageGroup: Identifiable, Hashable {
    @Attribute(.unique) var id: UUID
    var name: String

    @Relationship(deleteRule: .cascade, inverse: \UsageEntry.group)
    var entries: [UsageEntry] = []

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    static func == (lhs: UsageGroup, rhs: UsageGroup) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
