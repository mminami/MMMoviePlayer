//
// Created by mminami on 2017/10/27.
// Copyright (c) 2017 mminami. All rights reserved.
//

import Foundation
import UIKit

class MovieItemCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    static var nib: UINib {
        return UINib(nibName: "\(MovieItemCell.self)", bundle: nil)
    }
}
