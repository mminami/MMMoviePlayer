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

public extension Int {
    var timeString: String {
        let components = NSDateComponents()
        components.second = self

        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.hour, .minute, .second]

        return formatter.string(for: components as DateComponents)!
    }
}

public class PlayerView: UIView {
    public override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

public protocol MoviePlayerViewDataSource: class {
    func movieItem(in view: MoviePlayerView) -> MovieItem
}

public protocol MoviePlayerViewDelegate {
    func moviePlayerView(_ view: MoviePlayerView, unknownToPlayWith: MovieItem?)
    func moviePlayerView(_ view: MoviePlayerView, readyToPlayWith: MovieItem?)
    func moviePlayerView(_ view: MoviePlayerView, failedToPlayWith: MovieItem?)
    func moviePlayerView(_ view: MoviePlayerView, didPause movieItem: MovieItem?)
    func moviePlayerView(_ view: MoviePlayerView, didPlay movieItem: MovieItem?)
    func moviePlayerView(_ view: MoviePlayerView, waitingToPlayAtSpecifiedRate movieItem: MovieItem?)
}

public extension MoviePlayerViewDelegate {
    func moviePlayerView(_ view: MoviePlayerView, unknownToPlayWith: MovieItem?) {}
    func moviePlayerView(_ view: MoviePlayerView, readyToPlayWith: MovieItem?) {}
    func moviePlayerView(_ view: MoviePlayerView, failedToPlayWith: MovieItem?) {}
    func moviePlayerView(_ view: MoviePlayerView, didPause movieItem: MovieItem?) {}
    func moviePlayerView(_ view: MoviePlayerView, didPlay movieItem: MovieItem?) {}
    func moviePlayerView(_ view: MoviePlayerView, waitingToPlayAtSpecifiedRate movieItem: MovieItem?) {}
}

private var playerObserveContext = 0

public class MoviePlayerView: UIView {
    // MARK: enum

    enum ControlUIStatus {
        case hidden
        case show
    }

    // MARK: UI

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var progressTimeLabel: UILabel!
    @IBOutlet weak var slashLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!

    // MARK: UIAction

    @IBAction func playButtonDidTap(_ sender: UIButton) {
        if #available(iOS 10.0, *) {
            switch player.timeControlStatus {
            case .paused: player.play()
            case .playing: player.pause()
            case .waitingToPlayAtSpecifiedRate: break
            }
        } else {
            if player.rate == 0 {
                player.play()
                delegate?.moviePlayerView(self, didPause: movieItem)
            } else {
                player.pause()
                delegate?.moviePlayerView(self, didPlay: movieItem)
            }
        }
    }

    // MARK: Property

    public var dataSource: MoviePlayerViewDataSource?
    public var delegate: MoviePlayerViewDelegate?

    private var player = AVPlayer()
    private var movieItem: MovieItem?

    private var timeObserverToken: Any?

    private var observedKeyPaths: [String] {
        if #available(iOS 10.0, *) {
            return [#keyPath(AVPlayer.currentItem.status),
                    #keyPath(AVPlayer.rate),
                    #keyPath(AVPlayer.currentItem.duration),
                    #keyPath(AVPlayer.timeControlStatus)]
        } else {
            return [#keyPath(AVPlayer.currentItem.status),
                    #keyPath(AVPlayer.rate),
                    #keyPath(AVPlayer.currentItem.duration)]
        }
    }

    private var controlUIStatus: ControlUIStatus = .show {
        didSet {
            switch controlUIStatus {
            case .show: self.showControlUI()
            case .hidden: self.hideControlUI()
            }
        }
    }

    // MARK: Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    private func commonInit() {
        let bundle = Bundle(for: MoviePlayerView.self)
        bundle.loadNibNamed("\(MoviePlayerView.self)", owner: self, options: nil)

        translatesAutoresizingMaskIntoConstraints = false

        contentView.backgroundColor = backgroundColor

        playerView.backgroundColor = contentView.backgroundColor

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(type(of: self).didTapControlView(_:)))
        controlView.addGestureRecognizer(recognizer)
        controlView.backgroundColor = UIColor.clear

        progressTimeLabel.textColor = UIColor.white
        slashLabel.textColor = UIColor.white
        durationTimeLabel.textColor = UIColor.white

        slider.addTarget(self, action: #selector(type(of: self).sliderDidChangeValue(_:)), for: .valueChanged)

        self.addSubview(contentView)
    }

    // MARK: Life cycle

    public override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = self.bounds
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        let playerLayer = playerView.layer as! AVPlayerLayer
        playerLayer.player = player

        for keyPath in observedKeyPaths {
            self.player.addObserver(self,
                    forKeyPath: keyPath,
                    options: [.new, .initial],
                    context: &playerObserveContext)
        }
    }

    public override func removeFromSuperview() {
        super.removeFromSuperview()

        player.pause()

        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }

        removeObserver()
    }

    // MARK: API

    public func prepareToPlay() {
        guard let newMovieItem = self.dataSource?.movieItem(in: self) else {
            print("MovieItem is not set")
            return
        }

        movieItem = newMovieItem

        let asset = AVURLAsset(url: newMovieItem.videoURL, options: nil)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: DispatchQueue.main) { [unowned self] time in
            let timeProgress = Float(CMTimeGetSeconds(time))
            self.slider.value = timeProgress
            self.progressTimeLabel.text = Int(timeProgress).timeString
        }
    }

    public func play() {
        if self.player.currentItem?.status != AVPlayerItemStatus.readyToPlay {
            print("Can not play")
            return
        }

        player.play()

        controlUIStatus = .hidden
    }

    public func pause() {
        player.pause()
    }

    @objc private func sliderDidChangeValue(_ slider: UISlider) {
        let seekTime = CMTime(seconds: Double(slider.value), preferredTimescale: 1)
        player.seek(to: seekTime)
    }

    // MARK: Helper

    @objc private func didTapControlView(_ recognizer: UIGestureRecognizer) {
        switch controlUIStatus {
        case .hidden: controlUIStatus = .show
        case .show: controlUIStatus = .hidden
        }
    }

    func showControlUI() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.playButton.alpha = 1
            self.progressTimeLabel.alpha = 1
            self.durationTimeLabel.alpha = 1
            self.slashLabel.alpha = 1
            self.slider.alpha = 1
        }, completion: { completion in })
    }

    func hideControlUI() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.playButton.alpha = 0
            self.progressTimeLabel.alpha = 0
            self.durationTimeLabel.alpha = 0
            self.slashLabel.alpha = 0
            self.slider.alpha = 0
        }, completion: { completion in })
    }

    private func removeObserver() {
        for keyPath in observedKeyPaths {
            self.player.removeObserver(self, forKeyPath: keyPath)
        }
    }

    public override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
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
            handleStatus(status)
        case #keyPath(AVPlayer.rate):
            print("rate: \(player.rate)")
        case #keyPath(AVPlayer.currentItem.duration):
            let duration: CMTime
            if let value = change?[.newKey] as? NSValue {
                duration = value.timeValue
            } else {
                duration = kCMTimeZero
            }
            handleDuration(duration)
        case #keyPath(AVPlayer.timeControlStatus):
            print("timeControlStatus")
            if #available(iOS 10.0, *) {
                let status: AVPlayerTimeControlStatus
                if let statusNumber = change?[.newKey] as? NSNumber {
                    status = AVPlayerTimeControlStatus(rawValue: statusNumber.intValue)!
                } else {
                    fatalError("Unknown status")
                }
                handleTimeControlStatus(status)
            }
        default:
            fatalError("Unexpected keyPath: \(keyPath)")
        }
    }
}

// MARK: Handel Player Status

extension MoviePlayerView {
    fileprivate func isValid(_ time: CMTime) -> Bool {
        return time.isValid && time.value != 0
    }

    fileprivate func durationSeconds(_ time: CMTime) -> Float64 {
        return isValid(time) ? CMTimeGetSeconds(time) : 0
    }

    fileprivate func currentSeconds(_ time: CMTime) -> Float64 {
        return isValid(time) ? CMTimeGetSeconds(player.currentTime()) : 0
    }

    fileprivate func handleStatus( _ status: AVPlayerItemStatus) {
        switch status {
        case .unknown: delegate?.moviePlayerView(self, unknownToPlayWith: movieItem)
        case .readyToPlay: delegate?.moviePlayerView(self, readyToPlayWith: movieItem)
        case .failed: delegate?.moviePlayerView(self, failedToPlayWith: movieItem)
        }
    }

    fileprivate func handleDuration(_ time: CMTime) {
        slider.isEnabled = isValid(time)
        slider.maximumValue = Float(durationSeconds(time))
        slider.value = Float(currentSeconds(time))

        progressTimeLabel.isEnabled = isValid(time)
        progressTimeLabel.text = Int(currentSeconds(time)).timeString

        durationTimeLabel.isEnabled = isValid(time)
        durationTimeLabel.text = Int(durationSeconds(time)).timeString
    }

    @available(iOS 10.0, *)
    fileprivate func handleTimeControlStatus(_ status: AVPlayerTimeControlStatus) {
        switch status {
        case .paused:
            playButton.setTitle("再生", for: .normal)
            delegate?.moviePlayerView(self, didPause: movieItem)
        case .playing:
            playButton.setTitle("停止", for: .normal)
            delegate?.moviePlayerView(self, didPlay: movieItem)
        case .waitingToPlayAtSpecifiedRate:
            delegate?.moviePlayerView(self, waitingToPlayAtSpecifiedRate: movieItem)
        }
    }
}
