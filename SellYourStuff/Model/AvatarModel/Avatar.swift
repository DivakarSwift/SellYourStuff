//
//  Avatar.swift
//  MyChatApp
//
//  Created by MacBook  on 07/03/2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import Foundation
import ChattoAdditions

class Avatar: BaseMessageCollectionViewCellDefaultStyle {
    
    
    //hazir fonk cagirdik
    override func avatarSize(viewModel: MessageViewModelProtocol) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
    
    //Eğer sadece gelen mesajlarda avatari gostermek istersek asagidaki kod
    
    //return viewModel.isIncoming ? CGSize(width: 30, height: 30) : CGSize.zero
}
