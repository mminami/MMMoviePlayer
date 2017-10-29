//
// Created by mminami on 2017/10/27.
// Copyright (c) 2017 mminami. All rights reserved.
//

import Foundation

public struct MovieItem {
    let title: String
    let videoURL: URL
    let presenterName: String
    let description: String
    let thumbnailURL: URL
    let videoDuration: Int

    var videoDurationText: String {
        var components = DateComponents()
        components.second = videoDuration/1000

        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(for: components)!
    }
}
