//
// Created by mminami on 2017/10/27.
// Copyright (c) 2017 mminami. All rights reserved.
//

import Foundation

protocol Repository {
    associatedtype Output

    func load() -> [Output]
}

class MovieItemRepository: Repository {
    typealias Output = [MovieItemEntity]

    func load() -> [MovieItemEntity] {
        return [MovieItemEntity]()
    }
}
