//
// Created by mminami on 2017/10/27.
// Copyright (c) 2017 mminami. All rights reserved.
//

import Foundation

protocol Repository {
    associatedtype Output

    func load() -> Output
    var jsonObjects: [AnyObject] { get }
}

class MovieItemRepository: Repository {
    typealias Output = [MovieItemEntity]

    var jsonObjects: [AnyObject] {
        let path = Bundle.main.path(forResource: "contents", ofType: "json")!
        let url = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: url)
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [AnyObject]
    }

    func load() -> [MovieItemEntity] {
        var entities = [MovieItemEntity]()

        for item in jsonObjects {
            let movieContent = item as! [String:Any]

            let title = movieContent["title"] as! String
            let presenterName = movieContent["presenter_name"] as! String
            let description = movieContent["description"] as! String
            let thumbnailUrlString = movieContent["thumbnail_url"] as! String
            let videoUrlString = movieContent["video_url"] as! String
            let videoDuration = movieContent["video_duration"] as! Int

            let entity = MovieItemEntity(
                    title: title,
                    presenterName: presenterName,
                    description: description,
                    thumbnailUrlString: thumbnailUrlString,
                    videoUrlString: videoUrlString,
                    videoDuration: videoDuration
            )

            entities.append(entity)
        }

        return entities
    }
}
