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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = closeButton

        createMoviePlayerView()

        layoutMoviePlayerView()
    }

    func createMoviePlayerView() {
        let moviePlayerView = MoviePlayerView()
        moviePlayerView.dataSource = self
        moviePlayerView.delegate = self
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
}

extension MovieViewController: MoviePlayerViewDataSource {
    func movieItem(in view: MoviePlayerView) -> MovieItem {
        guard let newItem = movieItem else {
            fatalError("MovieItem is not set")
        }
        return newItem
    }
}

extension MovieViewController: MoviePlayerViewDelegate {
    func moviePlayerView(_ view: MoviePlayerView, unknownToPlayWith: MovieItem?) {
        print("unknownToPlayWith")
    }

    func moviePlayerView(_ view: MoviePlayerView, readyToPlayWith: MovieItem?) {
        print("readyToPlayWith")

        moviePlayerView.play()
    }

    func moviePlayerView(_ view: MoviePlayerView, failedToPlayWith: MovieItem?) {
        print("failedToPlayWith")
    }

    func moviePlayerView(_ view: MoviePlayerView, didPause movieItem: MovieItem?) {
        print("didPause")
    }

    func moviePlayerView(_ view: MoviePlayerView, didPlay movieItem: MovieItem?) {
        print("didPlay")
    }

    func moviePlayerView(_ view: MoviePlayerView, waitingToPlayAtSpecifiedRate movieItem: MovieItem?) {
        print("waitingToPlayAtSpecifiedRate")
    }
}
