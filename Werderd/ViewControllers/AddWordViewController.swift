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

        let textField = UITextField()
        textField.backgroundColor = .base
        self.view.addSubview(textField)

        constrain(self.okButton, textField, self.view) { okButton, textField, view in
//            okButton.width   == 100
//            okButton.height  == 100
            textField.centerX == okButton.centerX
            textField.centerY == okButton.centerY
            okButton.centerX == view.centerX
            okButton.centerY == view.centerY
        }

        self.view.backgroundColor = .white

        self.navigationItem.title = "New word"
    }

    @objc func tapped() {
        WerderdTypeModel.default.types.append("appended")
        self.dismiss(animated: true)
    }
}
