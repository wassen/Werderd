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

class AddWordViewController: UIViewController {
    weak var addButton: UIButton!
    weak var textField: UITextField!
    let disposeBag = DisposeBag()

    override func loadView(){
        self.view = self.newView()

        self.addButton = self.loadAddButton()
        self.textField = self.loadTextField()

        self.addConstraint()

        self.navigationItem.title = "New word"
    }

    override func viewDidLoad() {
        let viewModel = AddWordViewModel(
            word: self.textField.rx.text.orEmpty.asDriver(),
            tap: self.addButton.rx.tap.asDriver()
        )

        viewModel.isValid
            .drive(addButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }

    @objc func tapped() {
        if let text = self.textField.text {
            WerderdTypeModel.default.types.append(text)

            let realm = try! Realm()

            let s = Words()
            s.word = text

            try! realm.write() {
                realm.add(s)
            }
        }
        self.dismiss(animated: true)
    }
}

// MARK: private function for loadView
extension AddWordViewController {
    private func newView() -> UIView {
        let view = UIView()

        view.backgroundColor = .white

        return view
    }

    private func loadAddButton() -> UIButton {
        let addButton = UIButton()

        addButton.backgroundColor = .main
        addButton.setTitle("button", for: .normal)
        addButton.addTarget(
            self,
            action: #selector(tapped),
            for   : .touchUpInside
        )

        self.view.addSubview(addButton)

        return addButton
    }

    private func loadTextField() -> UITextField {
        let textField = UITextField()

        textField.backgroundColor = .base

        self.view.addSubview(textField)

        return textField
    }

    private func addConstraint() {
        constrain(self.addButton, self.textField, self.view) { okButton, textField, view in
            textField.centerX == view.centerX
            textField.centerY == view.centerY / 2
            textField.width   == view.width / 4
            okButton.centerX  == view.centerX
            okButton.centerY  == view.centerY
        }
    }
}
