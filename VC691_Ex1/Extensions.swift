//
//  Extensions.swift
//  VC691_Ex1
//
//  Created by kcmmac on 2017-11-14.
//  Copyright © 2017 kcmmac. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

extension SCNVector3 {
    func absoluteValue() -> SCNVector3 {
        return SCNVector3Make(abs(self.x), abs(self.y), abs(self.z))
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red: .random(),
                       green: .random(),
                       blue: .random(),
                       alpha: 1.0)
    }
}

func + (first: SCNVector3, second: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(first.x + second.x, first.y + second.y, first.z + second.z)
}

func - (first: SCNVector3, second: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(first.x - second.x, first.y - second.y, first.z - second.z)
}

