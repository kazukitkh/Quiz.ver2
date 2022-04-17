//
//  ConfirmTableViewCell.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/04/15.
//

import UIKit

protocol confirmDelegate {
    func confirmPressed()
}

class ConfirmTableViewCell: UITableViewCell {

    
    class var identifier: String { return String(describing: self) }
    class var nib: UINib { return UINib(nibName: identifier, bundle: nil) }
    var delegate: confirmDelegate?
    @IBOutlet weak var confirmButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func confirmButtonPressed(_ sender: Any) {
        self.delegate?.confirmPressed()
    }
    
}
