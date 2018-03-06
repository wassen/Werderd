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

        self.collectionView?.backgroundColor = .blue

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        let collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        collectionView.backgroundColor = .red

        self.view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

