//
// Created by 浅山和宣 on 2018/04/25.
// Copyright (c) 2018 Kazuki Asayama. All rights reserved.
//

import RealmSwift
import RxCocoa
import RxSwift

struct AddWordViewModel {
    // swiftlint:disable:next colon
    let word   : Driver<String>
    let isValid: Driver<Bool>
    let tap    : Signal<Void>
    let disposeBag = DisposeBag()

    init(
        word: Driver<String>,
        tap : Signal<Void>
    ) {
        self.word = word
        self.isValid = word.map {
            !$0.isEmpty
        }
        self.tap = tap
        self.tap
            .withLatestFrom(word)
            .emit(onNext: { word in
                let realm = try! Realm()
                let s = Words()

                s.word = word

                try! realm.write() {
                    realm.add(s)
                }
                WerderdTypeModel.default.types.append(word)
            }).disposed(by: disposeBag)
    }
}
