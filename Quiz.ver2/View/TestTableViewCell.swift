//
//  TestTableViewCell.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/03/31.
//

import UIKit
import SwipeCellKit

protocol InputTextTableCellDelegate {
    func cellTextFieldDidEndEditing(cell: TestTableViewCell, textFieldIndex: Int , value: String) -> ()
}

class TestTableViewCell: SwipeTableViewCell, UITextFieldDelegate {
    
    
    @IBOutlet weak var attribute1Height: NSLayoutConstraint!
    @IBOutlet weak var attribute2Height: NSLayoutConstraint!
    @IBOutlet weak var attribute3Height: NSLayoutConstraint!
    @IBOutlet weak var attribute4Height: NSLayoutConstraint!
    @IBOutlet weak var attribute5Height: NSLayoutConstraint!
    @IBOutlet weak var attribute6Height: NSLayoutConstraint!
    @IBOutlet weak var attribute7Height: NSLayoutConstraint!
    
    @IBOutlet weak var attribute1TextField: UITextField!
    @IBOutlet weak var attribute2TextField: UITextField!
    @IBOutlet weak var attribute3TextField: UITextField!
    @IBOutlet weak var attribute4TextField: UITextField!
    @IBOutlet weak var attribute5TextField: UITextField!
    @IBOutlet weak var attribute6TextField: UITextField!
    @IBOutlet weak var attribute7TextField: UITextField!
    
    var delegateOriginal: InputTextTableCellDelegate! = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        attribute1TextField.delegate = self
        attribute2TextField.delegate = self
        attribute3TextField.delegate = self
        attribute4TextField.delegate = self
        attribute5TextField.delegate = self
        attribute6TextField.delegate = self
        attribute7TextField.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("helloooooooo")
        textField.endEditing(true)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        var num = 0
        switch textField {
        case attribute1TextField:
            num = 0
        case attribute2TextField:
            num = 1
        case attribute3TextField:
            num = 2
        case attribute4TextField:
            num = 3
        case attribute5TextField:
            num = 4
        case attribute6TextField:
            num = 5
        case attribute7TextField:
            num = 6
        default:
            break
        }
        self.delegateOriginal.cellTextFieldDidEndEditing(cell: self, textFieldIndex: num, value: textField.text!)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        print("did change")
        return true
    }
    
}
