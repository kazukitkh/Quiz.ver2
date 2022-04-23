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
        confirmButton.setTitle("Submit", for: .normal)
        confirmButton.backgroundColor = UIColor.black
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 20
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func confirmButtonPressed(_ sender: Any) {
        confirmButton.backgroundColor = UIColor.red.withAlphaComponent(0.3)
        confirmButton.setTitleColor(.black, for: .normal)
        self.delegate?.confirmPressed()
    }
    
    @IBAction func confirmButtonTouchDown(_ sender: Any) {
        confirmButton.backgroundColor = UIColor.black
        confirmButton.setTitleColor(.white, for: .normal)
    }
    
    
}
