//
//  File.swift
//  LetgoClone
//
//  Created by MacBook  on 9.08.2018.
//  Copyright © 2018 Onurcan Yurt. All rights reserved.
//

import Foundation
import FacebookCore


struct MyProfileRequest: GraphRequestProtocol {
    struct Response: GraphResponseProtocol {
        var name:String?
        var email:String?
        var id:String?
        init(rawResponse: Any?) {
            // Decode JSON from rawResponse into other properties here.
            if let response = rawResponse as? [String:Any] {
                name = (response["name"] as? String) ?? ""
                email = (response["email"] as? String) ?? ""
                id = (response["id"] as? String) ?? ""
            }
        }
    }
    
    var graphPath = "/me"
    var parameters: [String : Any]? = ["fields": "id, name,email"]
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    
}
