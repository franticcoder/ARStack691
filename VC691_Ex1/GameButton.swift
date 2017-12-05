//
//  GameButton.swift
//  VC691_Ex1
//
//  Created by kcmmac on 2017-11-21.
//  Copyright © 2017 kcmmac. All rights reserved.
//

import Foundation
import UIKit

class GameButton : UIButton {
    
    var callback : () -> ()
    
    init(frame: CGRect, callback: @escaping () -> () ) {
        self.callback = callback
        super.init(frame: frame)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.callback()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
}
