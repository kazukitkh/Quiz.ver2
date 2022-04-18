//
//  SideMenuViewController.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/04/14.
//

import UIKit

protocol SideMenuViewDelegate {
    func selectedCell(_ row: Int)
    func attributeRankSelected(rank: [Int])
    func attributeNameSelected(attIdx: Int)
}

class SideMenuViewController: UIViewController, confirmDelegate {
    func confirmPressed() {
        var temp = [Int](repeating: 0, count: 7)
        for att in rankedAttribute {
            temp[att] += 1
        }
        if temp.firstIndex(where: {$0 > 1}) == nil {
            print("side menu rank sent")
            self.delegate?.attributeRankSelected(rank: rankedAttribute)
        } else {
            self.makeAlerts(title: "Error", message: "No duplication in rank, allowed", buttonName: "OK")
        }
    }
    
    @IBOutlet weak var sideMenuTableView: UITableView!
    
    var isLearnEnd: Bool = false {
        didSet {
            self.sideMenuTableView.reloadData()
        }
    }
    var numberOfAttributes: Int = 2
    var menu: [SideMenuModel] = []
    var changeAttributeRank: Bool = false {
        didSet {
            self.sideMenuTableView.reloadData()
        }
    }
    var changeAttributeName: Bool = false {
        didSet {
            self.sideMenuTableView.reloadData()
        }
    }
    var attributes: [String] = [] {
        didSet {
            self.sideMenuTableView.reloadData()
        }
    }
    var rankedAttribute: [Int] = [] {
        didSet {
            numberOfAttributes = rankedAttribute.count
            self.sideMenuTableView.reloadData()
        }
    }
    var defaultHighlightedCell: Int = 0
    var delegate: SideMenuViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sideMenuTableView.delegate = self
        self.sideMenuTableView.dataSource = self
        self.sideMenuTableView.backgroundColor = .white
        self.sideMenuTableView.separatorStyle = .none
        
//        DispatchQueue.main.async {
//            let defaultRow = IndexPath(row: self.defaultHighlightedCell, section: 0)
//            self.sideMenuTableView.selectRow(at: defaultRow, animated: false, scrollPosition: .none)
//        }
        
        self.sideMenuTableView.register(SideMenuTableViewCell.nib, forCellReuseIdentifier: SideMenuTableViewCell.sideMenuIdentifier)
        self.sideMenuTableView.register(NumberOfAttributesCell.nib, forCellReuseIdentifier: NumberOfAttributesCell.identifier)
        self.sideMenuTableView.register(ChangeAttributeTableViewCell.nib, forCellReuseIdentifier: ChangeAttributeTableViewCell.identifier)
        self.sideMenuTableView.register(ConfirmTableViewCell.nib, forCellReuseIdentifier: ConfirmTableViewCell.identifier)
        
        self.sideMenuTableView.reloadData()
    }
    
    
    func makeAttributeMenu(idx: Int) -> [UIMenuElement] {
        var actions = [UIMenuElement]()
        for (attIdx, att) in attributes.enumerated() {
            actions.append(UIAction(title: att, image: nil, state: self.rankedAttribute[idx] == attIdx ? .on : .off, handler: { (_) in
                self.rankedAttribute[idx] = attIdx
                self.sideMenuTableView.reloadData()
            }))
        }
        return actions
    }
    
    func makeNumberMenu() -> [UIMenuElement] {
        var actions = [UIMenuElement]()
        for num in 2...7 {
            actions.append(UIAction(title: String(num), image: nil, state: self.numberOfAttributes == num ? .on : .off, handler: { (_) in
                while num > self.rankedAttribute.count {
                    self.rankedAttribute.append(0)
                }
                self.rankedAttribute = Array(self.rankedAttribute[0..<num])
                self.numberOfAttributes = num
                self.sideMenuTableView.reloadData()
            }))
        }
        return actions
    }
}

extension SideMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

extension SideMenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLearnEnd {
            return 1
        }
        if changeAttributeRank {
            return numberOfAttributes + 2
        } else if changeAttributeName {
            return attributes.count
        } else {
            return self.menu.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        print("indexPath.row: \(indexPath.row)")
        if changeAttributeRank {
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: NumberOfAttributesCell.identifier, for: indexPath) as? NumberOfAttributesCell else {
                    fatalError("xib doesn't exist.")
                }
                cell.labelText.text = "Select number of Attributes:"
                cell.numberPullDown.menu = UIMenu(title: "", image: nil, options: .displayInline, children: makeNumberMenu())
                cell.numberPullDown.showsMenuAsPrimaryAction = true
                cell.numberPullDown.setTitle(String(self.numberOfAttributes), for: .normal)
                return cell
                
            } else if indexPath.row < 1 + numberOfAttributes {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ChangeAttributeTableViewCell.identifier, for: indexPath) as? ChangeAttributeTableViewCell else {
                    fatalError("xib doesn't exist.")
                }
                cell.numberLabel.text = String(indexPath.row)
                cell.pullDownCell.menu = UIMenu(title: "", options: .displayInline, children: makeAttributeMenu(idx: indexPath.row - 1))
                cell.pullDownCell.showsMenuAsPrimaryAction = true
                cell.pullDownCell.setTitle(self.attributes[rankedAttribute[indexPath.row - 1]], for: .normal)
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ConfirmTableViewCell.identifier, for: indexPath) as? ConfirmTableViewCell else {
                    fatalError("xib doesn't exist.")
                }
                cell.delegate = self
                return cell
            }
        } else if changeAttributeName {
            let cell = tableView.dequeueReusableCell(withIdentifier: SideMenuTableViewCell.sideMenuIdentifier, for: indexPath) as! SideMenuTableViewCell
            cell.iconImageView.image = UIImage(systemName: "pencil")
            cell.titleLabel.text = self.attributes[indexPath.row]
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: SideMenuTableViewCell.sideMenuIdentifier, for: indexPath) as! SideMenuTableViewCell
            cell.iconImageView.image = self.menu[indexPath.row].icon
            cell.titleLabel.text = self.menu[indexPath.row].title
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if changeAttributeRank {
            return
        } else if changeAttributeName {
            self.delegate?.attributeNameSelected(attIdx: indexPath.row)
        } else {
            self.delegate?.selectedCell(indexPath.row)
        }
    }
    
    func makeAlerts(title: String, message: String, buttonName: String) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: buttonName, style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
}
