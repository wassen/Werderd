//
//  AddWordViewController.swift
//  Werderd
//
//  Created by 浅山和宣 on 2018/03/17.
//  Copyright © 2018年 Kazuki Asayama. All rights reserved.
//

import UIKit
import Cartography
import RealmSwift
import RxSwift
import RxCocoa


class AddWordViewController: UIViewController {
    var okButton: UIButton!
    var text: String?
    var textField: UITextField!
    let disposeBag = DisposeBag()

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
        
        let viewModel = AddWordViewModel(
            input: self.textField.rx.text.orEmpty.asDriver()
        )
        
        viewModel.isValid
            .drive(okButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }

    @objc func tapped() {
        if let text = self.textField.text {
            WerderdTypeModel.default.types.append(text)

            let realm = try! Realm()

            let s = Struct()
            s.word = text

            try! realm.write() {
                realm.add(s)
            }
        }
        self.dismiss(animated: true)
    }
}

class Struct: Object {
    @objc dynamic var word: String = ""
}

struct AddWordViewModel {
    let word: Driver<String>
    let isValid: Driver<Bool>
    
    init(input: Driver<String>) {
        word = input
        isValid = word.map {
            !$0.isEmpty
        }
    }
}
