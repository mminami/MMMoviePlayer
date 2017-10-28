//
// Created by mminami on 2017/10/27.
// Copyright (c) 2017 mminami. All rights reserved.
//

import Foundation
import UIKit

protocol CellProtocol {
    static var identifier: String { get }
}
protocol NibProtocol {
    static var nib: UINib { get }
}

class MovieItemCell: UITableViewCell, CellProtocol, NibProtocol  {
    static var identifier =  "\(MovieItemCell.self)"

    static var nib: UINib {
        return UINib(nibName: "\(MovieItemCell.self)", bundle: nil)
    }

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    func configure(_ movieItem: MovieItem) {
        titleLabel.text = movieItem.title
        descriptionLabel.text = movieItem.description
        durationLabel.text = movieItem.videoDurationText
    }
}
