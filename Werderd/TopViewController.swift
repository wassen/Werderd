//
//  ViewController.swift
//  Werderd
//
//  Created by 浅山和宣 on 2017/08/18.
//  Copyright © 2017年 Kazuki Asayama. All rights reserved.
//

import UIKit

class TopViewController: UICollectionViewController {
    override func loadView() {
        self.view = UIView()
        self.navigationItem.title = "title"
        self.collectionView = self.newCollectionView()

//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
//        collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
//        collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
//        collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView!.delegate = self
        self.collectionView!.dataSource = self
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(
        _ collectionView              : UICollectionView,
        numberOfItemsInSection section: Int
        ) -> Int {
        return 3
    }

    override func collectionView(
        _ collectionView       : UICollectionView,
        cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "Cell",
            for                : indexPath
        )
        
        let colors = [
            UIColor.red,
            UIColor.blue,
            UIColor.green,
            UIColor.yellow
        ]
        cell.backgroundColor = colors[indexPath.row]
        return cell
    }
}

// MARK: Private Method for loadView
extension TopViewController {
    private func newCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(
            width : 100,
            height: 100
        )

        let collectionView = UICollectionView(
            frame               : CGRect(),
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .black

        return collectionView
    }
}
