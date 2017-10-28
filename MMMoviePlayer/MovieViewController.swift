//
// Created by mminami on 2017/10/28.
// Copyright (c) 2017 mminami. All rights reserved.
//

import Foundation
import UIKit

class MovieViewController: UIViewController {
    weak var moviePlayerView: MoviePlayerView!

    var topConstraint: NSLayoutConstraint!
    var leadConstraint: NSLayoutConstraint!
    var trailingConstraint: NSLayoutConstraint!
    var bottomConstraint: NSLayoutConstraint!

    var movieItem: MovieItem?

    private lazy var closeButton: UIBarButtonItem = {
        return UIBarButtonItem(
                title: "Close",
                style: .plain,
                target: self,
                action: #selector(type(of: self).didTapCloseButton(_:))
        )
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = closeButton

        createMoviePlayerView()

        layoutMoviePlayerView()

        registerNotification()
    }

    func createMoviePlayerView() {
        let moviePlayerView = MoviePlayerView()
        moviePlayerView.dataSource = self
        self.view.addSubview(moviePlayerView)
        self.moviePlayerView = moviePlayerView
    }

    func layoutMoviePlayerView() {
        moviePlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        moviePlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        moviePlayerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        moviePlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")

        moviePlayerView.prepareToPlay()
    }

    @objc private func didTapCloseButton(_ sender: UIBarButtonItem) {
        // TODO: Stop movie

        dismiss(animated: true)
    }

    private func registerNotification() {
        NotificationCenter.default.addObserver(self,
                selector: #selector(type(of: self).moviePlayerFailed(_:)),
                name: Notification.Name.MMMoviePlayer.failed.name,
                object: nil)
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(type(of: self).moviePlayerReadyToPlay(_:)),
                name: Notification.Name.MMMoviePlayer.readyToPlay.name,
                object: nil)
        NotificationCenter.default.addObserver(self,
                selector: #selector(type(of: self).moviePlayerUnknown(_:)),
                name: Notification.Name.MMMoviePlayer.unknown.name,
                object: nil)
    }
}

extension MovieViewController {
    @objc private func moviePlayerFailed(_ notification: Notification) {
        print("failed")
    }

    @objc private func moviePlayerReadyToPlay(_ notification: Notification) {
        print("ready to play")

        moviePlayerView.play()
    }

    @objc private func moviePlayerUnknown(_ notification: Notification) {
        print("unknown")
    }
}

extension MovieViewController: MoviePlayerViewDataSource {
    func movieItem(in view: MoviePlayerView) -> MovieItem {
        guard let newItem = movieItem else {
            fatalError("MovieItem is not set")
        }
        return newItem
    }
}
