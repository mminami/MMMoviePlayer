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

extension Float {
    var timeString: String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, self))

        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.hour, .minute, .second]

        return formatter.string(for: components as DateComponents)!
    }
}

protocol MoviePlayerViewDataSource: class {
    func movieItem(in view: MoviePlayerView) -> MovieItem
}

private var playerObserveContext = 0

class MoviePlayerView: UIView {
    // MARK: UI

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var progressTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!

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

    private var timeObserverToken: Any?

    private let observedKeyPaths = [
        #keyPath(AVPlayer.currentItem.status),
        #keyPath(AVPlayer.rate),
        #keyPath(AVPlayer.currentItem.duration),
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

        progressTimeLabel.textColor = UIColor.white
        durationTimeLabel.textColor = UIColor.white

        slider.addTarget(self, action: #selector(type(of: self).sliderDidChangeValue(_:)), for: .valueChanged)

        self.addSubview(contentView)
    }

    // MARK: Life cycle

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = self.bounds
    }

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

        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }

        removeObserver()
    }

    // MARK: API

    func prepareToPlay() {
        guard let movieItem = self.dataSource?.movieItem(in: self) else {
            print("MovieItem is not set")
            return
        }

        let asset = AVURLAsset(url: movieItem.videoURL, options: nil)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: DispatchQueue.main) { [unowned self] time  in
            let timeProgress = Float(CMTimeGetSeconds(time))
            self.slider.value = timeProgress
            self.progressTimeLabel.text = timeProgress.timeString
         }
    }

    func play() {
        if self.player.currentItem?.status != AVPlayerItemStatus.readyToPlay {
            print("Can not play")
            return
        }

        playerView.player?.play()
    }

     @objc private func sliderDidChangeValue(_ slider: UISlider) {
         let seekTime = CMTime(seconds: Double(slider.value), preferredTimescale: 1)
         player.seek(to: seekTime)
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
        case #keyPath(AVPlayer.currentItem.duration):
            let duration: CMTime
            if let value = change?[.newKey] as? NSValue {
                duration = value.timeValue
            } else {
                duration = kCMTimeZero
            }

            let isValidDuration = duration.isValid && duration.value != 0
            let durationSeconds = isValidDuration ? Float(CMTimeGetSeconds(duration)) : 0.0
            let currentTime = isValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0

            slider.isEnabled = isValidDuration
            slider.maximumValue = durationSeconds
            slider.value = currentTime

            progressTimeLabel.isEnabled = isValidDuration
            progressTimeLabel.text = currentTime.timeString

            durationTimeLabel.isEnabled = isValidDuration
            durationTimeLabel.text = durationSeconds.timeString

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
