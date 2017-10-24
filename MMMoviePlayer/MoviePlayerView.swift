//
//  MoviePlayerView.swift
//  MMMoviePlayer
//
//  Created by mminami on 2017/10/22.
//  Copyright © 2017 mminami. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


protocol MoviePlayerViewDataSource: class {
    func movieURL(in view: MoviePlayerView) -> URL
}

private var playerObserveContext = 0

class MoviePlayerView: UIView {
    // MARK: UI

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var progressTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!

    // MARK: UIAction

    @IBAction func playButtonDidTap(_ sender: UIButton) {
        if let status = playerView.player?.timeControlStatus {
            switch status {
            case .paused: player.play()
            case .playing: player.pause()
            case .waitingToPlayAtSpecifiedRate: break
            }
        }
    }

    // MARK: Property

    var dataSource: MoviePlayerViewDataSource?

    private var player =  AVPlayer()

    private let observedKeyPaths = [
        #keyPath(AVPlayer.currentItem.status),
        #keyPath(AVPlayer.rate),
        #keyPath(AVPlayer.timeControlStatus),
    ]

    // MARK: Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("\(MoviePlayerView.self)", owner: self, options: nil)

        translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(contentView)

        print("commonInit")
    }

    // MARK: Life cycle
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        playerView.player = player

        for keyPath in observedKeyPaths {
            self.player.addObserver(self,
                    forKeyPath: keyPath,
                    options: [.new, .initial],
                    context: &playerObserveContext)
        }
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()

        player.pause()

        removeObserver()
    }

    // MARK: API

    func prepareToPlay() {
        guard let url = self.dataSource?.movieURL(in: self) else {
            print("URL is not set")
            return
        }

        let asset = AVURLAsset(url: url, options: nil)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
    }

    func play() {
        if self.player.currentItem?.status != AVPlayerItemStatus.readyToPlay {
            print("Can not play")
            return
        }

        playerView.player?.play()
    }

    // MARK: Helper

    private func removeObserver() {
        for keyPath in observedKeyPaths {
            self.player.removeObserver(self, forKeyPath: keyPath)
        }
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {

        guard context == &playerObserveContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        guard let keyPath = keyPath else {
            return
        }

        switch keyPath {
        case #keyPath(AVPlayer.currentItem.status):
            let status: AVPlayerItemStatus

            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            switch status {
            case .unknown:
                NotificationCenter.default.post(
                    name: Notification.Name.MMMoviePlayer.unknown.name,
                    object: nil
                )
            case .readyToPlay:
                NotificationCenter.default.post(
                    name: Notification.Name.MMMoviePlayer.readyToPlay.name,
                    object: nil
                )
            case .failed:
                NotificationCenter.default.post(
                    name: Notification.Name.MMMoviePlayer.failed.name,
                    object: nil
                )
            }
        case #keyPath(AVPlayer.rate):
            print("rate: \(player.rate)")
        case #keyPath(AVPlayer.timeControlStatus):
            print("timeControlStatus")

            let status: AVPlayerTimeControlStatus

            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerTimeControlStatus(rawValue: statusNumber.intValue)!
            } else {
                fatalError("Unknown statu")
            }

            switch status {
            case .paused:
                print("paused")
                playButton.setTitle("再生", for: .normal)
            case .playing:
                print("playing")
                playButton.setTitle("停止", for: .normal)
            case .waitingToPlayAtSpecifiedRate:
                print("waitingToPlayAtSpecifiedRate")
            }
        default:
            fatalError("Unexpected keypath: \(keyPath)")
        }
    }
}
