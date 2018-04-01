//
//  AddWordViewController.swift
//  Werderd
//
//  Created by 浅山和宣 on 2018/03/17.
//  Copyright © 2018年 Kazuki Asayama. All rights reserved.
//

import UIKit
import Cartography

class AddWordViewController: UIViewController {
    var okButton: UIButton!
    var text: String?
    var textField: UITextField!

    override func loadView(){
        self.view = UIView()
        self.okButton = UIButton()
        self.okButton.backgroundColor = .main
        self.okButton.setTitle("button", for: .normal)

        self.okButton.addTarget(
            self,
            action: #selector(tapped),
            for   : .touchUpInside
        )

        self.view.addSubview(okButton)

        self.textField = UITextField()
        textField.backgroundColor = .base
        self.view.addSubview(textField)

        constrain(self.okButton, textField, self.view) { okButton, textField, view in
//            okButton.width   == 100
//            okButton.height  == 100
            textField.centerX == view.centerX
            textField.centerY == view.centerY / 2
            textField.width   == view.width / 4
            okButton.centerX  == view.centerX
            okButton.centerY  == view.centerY
        }

        self.view.backgroundColor = .white

        self.navigationItem.title = "New word"
    }
    
    override func viewDidLoad() {
//        self.textField.delegate = self
    }

    @objc func tapped() {
        if let text = self.textField.text {
            WerderdTypeModel.default.types.append(text)
        }
        self.dismiss(animated: true)
    }
}
