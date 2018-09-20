//
//  ProfileCell.swift
//  LetgoClone
//
//  Created by MacBook  on 25.07.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import UIKit

//CollectionviewCell sinifidir ve icindeki fotoyu ekledik
//collectionview siniflarinda bu sinifi kullaniyoruz

class ProfileCell: UICollectionViewCell {
    @IBOutlet weak var itemImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        //eger cell fotosunu yuvarlamak istersersek yani kenarlarini yumasakmak icin
     //  itemImage.layer.cornerRadius = itemImage.frame.size.width / 2.5
      // itemImage.clipsToBounds = true
        
    }

    
}
