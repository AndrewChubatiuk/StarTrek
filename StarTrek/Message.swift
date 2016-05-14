//
//  Serializator.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/7/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//


import Foundation

@objc protocol Exchangable {
    func objectUpdatesMessage(attribute: String) -> [String: AnyObject]
    static func createFromData(data: NSDictionary) -> Exchangable
}

struct Message {
    
    static func createMessageArray(objectArray: [Exchangable]) -> [[String: AnyObject]] {
        var resultArray = [[String: AnyObject]]()
        for obj in objectArray {
            resultArray.append(obj.objectUpdatesMessage("initial"))
        }
        return resultArray
    }
    
    static func unpackMessageArray<T: Exchangable>(array: [T], data: NSArray) -> [T] {
        var result = [T]()
        for d in data {
            let objDict = d as! NSDictionary
            result.append(T.createFromData(objDict) as! T)
        }
        return result
    }
}