//
//  FolderTableViewCell.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/03/19.
//

import UIKit
import SwipeCellKit

class FolderTableViewCell: SwipeTableViewCell {

    @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var numberOfContent: UILabel!
    @IBOutlet weak var cellScreen: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
