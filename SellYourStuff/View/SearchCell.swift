//
//  SearchCell.swift
//  LetgoClone
//
//  Created by MacBook  on 1.08.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit

class SearchCell: UITableViewCell {

    @IBOutlet weak var fiyatLbl: UILabel!
    @IBOutlet weak var photoCell: UIImageView!
    @IBOutlet weak var urunBaslik: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
