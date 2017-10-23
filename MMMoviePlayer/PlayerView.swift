//
//  PlayerView.swift
//  MMMoviePlayer
//
//  Created by mminami on 2017/10/23.
//  Copyright © 2017 mminami. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
