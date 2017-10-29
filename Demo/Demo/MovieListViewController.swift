//
//  MovieListViewController.swift
//  MMMoviePlayer
//
//  Created by mminami on 2017/10/27.
//  Copyright © 2017 mminami. All rights reserved.
//

import Foundation
import UIKit

class MovieListViewController: UIViewController {
    weak var tableView: UITableView!

    private var downloadImageData = [IndexPath: Data]()

    private var deviceOrientation: UIInterfaceOrientation?

    var movieItems = [MovieItem]()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        createMovieItems()

        createTableView()

        layoutTableView()

        deviceOrientation = UIApplication.shared.statusBarOrientation

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(type(of: self).deviceOrientationDidChange(_:)),
            name: Notification.Name.UIDeviceOrientationDidChange,
            object: nil
        )
    }

    @objc private func deviceOrientationDidChange(_ notificatron: Notification) {
        deviceOrientation = UIApplication.shared.statusBarOrientation
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let orientation = deviceOrientation {
            if orientation != UIApplication.shared.statusBarOrientation {
                UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            }
        }
    }

    private func createMovieItems() {
        for entity in MovieItemRepository().load() {
            let videoURL = URL(string: entity.videoUrlString)!
            let thumbnailURL = URL(string: entity.thumbnailUrlString)!

            let item = MovieItem(
                    title: entity.title,
                    videoURL: videoURL,
                    presenterName: entity.presenterName,
                    description: entity.description,
                    thumbnailURL: thumbnailURL,
                    videoDuration: entity.videoDuration)

            movieItems.append(item)
        }
    }

    private func createTableView() {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MovieItemCell.nib, forCellReuseIdentifier: MovieItemCell.identifier)
        self.view.addSubview(tableView)
        self.tableView = tableView
    }

    private func layoutTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }
}

extension MovieListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MovieItemCell.identifier) as? MovieItemCell else {
            fatalError("Invalid cell identifier: \(MovieItemCell.identifier)")
        }

        let movieItem = movieItems[indexPath.row]

        cell.selectionStyle = .none
        cell.configure(movieItem)

        if let imageData = downloadImageData[indexPath] {
            cell.thumbnailImageView.image = UIImage(data: imageData)
        } else {
            var request = URLRequest(url: movieItem.thumbnailURL)
            request.httpMethod = "GET"

            DispatchQueue.global().async {
                let task = URLSession.shared.downloadTask(with: request) { (url: URL?, response: URLResponse?, error: Error?) -> Void in
                    DispatchQueue.main.async {
                        if let newURL = url {
                            do {
                                let newImageData = try Data(contentsOf: newURL)
                                self.downloadImageData[indexPath] = newImageData
                                cell.thumbnailImageView.image = UIImage(data: newImageData)
                            } catch {
                                print("Can not create image from location: \(newURL)")
                            }
                        }
                    }
                }
                task.resume()
            }
        }

        cell.setNeedsLayout()

        return cell
    }
}

extension MovieListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UINavigationBar.appearance().tintColor = UIColor.white

        let movieVC = MovieViewController()

        let navigationVC = UINavigationController(rootViewController: movieVC)

        let titleLabel = UILabel()
        titleLabel.text = movieItems[indexPath.row].title
        titleLabel.textColor = UIColor.white
        titleLabel.sizeToFit()

        movieVC.movieItem = movieItems[indexPath.row]
        movieVC.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        movieVC.navigationController?.navigationBar.shadowImage = UIImage()
        movieVC.navigationController?.navigationBar.isTranslucent = true
        movieVC.navigationItem.titleView = titleLabel

        present(navigationVC, animated: true)
    }
}
