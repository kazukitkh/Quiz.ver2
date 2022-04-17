//
//  SideMenuTableViewCell.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/04/14.
//

import UIKit

class SideMenuTableViewCell: UITableViewCell {

    class var sideMenuIdentifier: String { return String(describing: self) }
    class var nib: UINib { return UINib(nibName: sideMenuIdentifier, bundle: nil) }
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = .clear
        self.iconImageView.tintColor = .white
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
