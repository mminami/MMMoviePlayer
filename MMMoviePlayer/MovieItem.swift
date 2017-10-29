//
// Created by mminami on 2017/10/27.
// Copyright (c) 2017 mminami. All rights reserved.
//

import Foundation

public struct MovieItem {
    public let title: String
    public let videoURL: URL
    public let presenterName: String
    public let description: String
    public let thumbnailURL: URL
    public let videoDuration: Int

    public var videoDurationText: String {
        var components = DateComponents()
        components.second = videoDuration/1000

        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(for: components)!
    }

    public init(title: String,
                videoURL: URL,
                presenterName: String,
                description: String,
                thumbnailURL: URL,
                videoDuration: Int) {
        self.title = title
        self.videoURL = videoURL
        self.presenterName = presenterName
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.videoDuration = videoDuration
    }
}
