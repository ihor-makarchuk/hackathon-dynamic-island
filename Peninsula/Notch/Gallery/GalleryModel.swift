import SwiftUI

struct GalleryType {
    var size: CGSize
    var displayed: Bool
}

enum GalleryItem: Int, Codable, Hashable, Equatable {
    case todo

    func count() -> Int { 1 }
    func toTitle() -> String { "Todo" }
}


class GalleryModel: ObservableObject {
    static let shared = GalleryModel()

    @Published var currentItem: GalleryItem = .todo
}
