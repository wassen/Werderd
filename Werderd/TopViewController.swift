//
//  ViewController.swift
//  Werderd
//
//  Created by 浅山和宣 on 2017/08/18.
//  Copyright © 2017年 Kazuki Asayama. All rights reserved.
//

import UIKit

class TopViewController: UICollectionViewController {

    var werderdTypes: [String] = WerderdTypeModel.default.types

    @objc func reloadView() {
        self.collectionView!.reloadData()
        print("reloading")
    }

    override func loadView() {
        self.view = UIView()
        self.navigationItem.title = "title"
        self.collectionView = self.newCollectionView()
        self.collectionView!.backgroundColor = Colors.orange.color

        let button = UIButton()
        button.setTitle("Tap Me!", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.frame = CGRect(
            origin: CGPoint(x: 100, y: 400),
            size: CGSize(width: 100, height: 50)
        )
        button.addTarget(
            self,
            action: #selector(tapped),
            for   : .touchUpInside
        )

        self.view.addSubview(button)

//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
//        collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
//        collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
//        collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true

        self.navigationItem.setRightBarButton(
            UIBarButtonItem(
                barButtonSystemItem: UIBarButtonSystemItem.add,
                target             : self,
                action             : #selector(add)
            ),
            animated           : true
        )
    }

    @objc func tapped() {
        WerderdTypeModel.default.types = ["wassen"]
    }

    @objc func add() {
        WerderdTypeModel.default.types.append("appended")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView!.delegate = self
        self.collectionView!.dataSource = self
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadView),
            name: Notification.Name("WerderdTypeModel_types"),
            object: nil
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(
        _ collectionView              : UICollectionView,
        numberOfItemsInSection section: Int
        ) -> Int {
        return WerderdTypeModel.default.types.count
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
            Colors.orange.color,
            Colors.orange.color,
            Colors.cyan.color,
            Colors.purple.color
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
