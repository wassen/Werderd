//
// Created by 浅山和宣 on 2018/04/25.
// Copyright (c) 2018 Kazuki Asayama. All rights reserved.
//

import RxCocoa

struct AddWordViewModel {
    // swiftlint disable colon
    let word   : Driver<String>
    let isValid: Driver<Bool>
    // swiftlint enable colon

//        input.doneTap
//            .emit(onNext: { [weak self] _ in
//                guard let `self` = self else { return }
//
//                self.dependency.wireframe.goToResultScreen(
//                    with: selectedBadgesRelay.value
//                )
//            })
//            .disposed(by: self.disposeBag)

    init(
        word: Driver<String>,
        tap : Signal<Void>
    ) {
        self.word = word
        self.isValid = word.map {
            !$0.isEmpty
        }

        tap.emit {

        }
    }
}
