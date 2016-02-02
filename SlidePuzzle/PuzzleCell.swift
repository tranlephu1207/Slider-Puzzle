//
//  PuzzleImage.swift
//  SplittingImage
//
//  Created by Tran Le Phu on 10/10/15.
//  Copyright © 2015 AnsonTran. All rights reserved.
//

import UIKit

class PuzzleCell: UIImageView {
    
    var correctNum:Int!
    var currentNum:Int!
    
    var isCorrectNum:Bool!
    var isBlankCell:Bool!
    
    var posLabel:UILabel!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init (imageView : UIImageView) {
        super.init(frame: imageView.frame)
        self.image = imageView.image
        
        posLabel = UILabel(frame: CGRectMake(5, 5, 25, 25))
        posLabel.textColor = UIColor.redColor()
        posLabel.font = posLabel.font.fontWithSize(15)
        self.addSubview(posLabel)
        
    }
    
    convenience init() {
        self.init(frame : CGRect(x: 0, y: 0, width: 100, height: 100))
        self.isBlankCell = false
    }
    
}

