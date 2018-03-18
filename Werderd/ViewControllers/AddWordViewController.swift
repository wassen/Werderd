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
        self.okButton.backgroundColor = .white
        self.okButton.setTitle("button", for: .normal)

        self.okButton.addTarget(
            self,
            action: #selector(tapped),
            for   : .touchUpInside
        )

        self.view.addSubview(okButton)
        constrain(self.okButton, self.view) { okButton, view in
//            okButton.width   == 100
//            okButton.height  == 100
            okButton.centerX == view.centerX
            okButton.centerY == view.centerY
        }

        self.view.backgroundColor = .cyan
    }

    @objc func tapped() {
        WerderdTypeModel.default.types.append("appended")
        self.dismiss(animated: true)
    }
}
