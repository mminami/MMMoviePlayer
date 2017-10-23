//
// Created by mminami on 2017/10/22.
// Copyright (c) 2017 mminami. All rights reserved.
//

import Foundation

extension Notification.Name {
    enum MMMoviePlayer {
        case unknown
        case readyToPlay
        case failed

        var name: Notification.Name {
            switch self {
            case .unknown: return Notification.Name.init("unknownNotification")
            case .readyToPlay: return Notification.Name.init("readyToPlayNotification")
            case .failed: return Notification.Name.init("failedNotification")
            }
        }
    }
}
