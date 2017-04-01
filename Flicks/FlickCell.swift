//
//  FlickCell.swift
//  Flicks
//
//  Created by Angie Lal on 3/30/17.
//  Copyright © 2017 Angie Lal. All rights reserved.
//

import UIKit

class FlickCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    
    @IBOutlet weak var posterView: UIImageView!
 
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
