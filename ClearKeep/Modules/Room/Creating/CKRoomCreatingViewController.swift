//
//  CKRoomCreatingViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 1/19/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomCreatingViewController: MXKViewController {
    
    // MARK: - OUTLET
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - ENUM
    
    private enum Section: Int {
        case option = 0
        case name   = 1
        case topic  = 2
        
        static var count: Int { return 3}
    }
    
    // MARK: - CLASS
    
    class func instance() -> CKRoomCreatingViewController {
        let instance = CKRoomCreatingViewController(nibName: self.nibName, bundle: nil)
        return instance
    }
    
    class func instanceForNavigationController(completion: ((_ instance: CKRoomCreatingViewController) -> Void)?) -> UINavigationController {
        let vc = self.instance()
        completion?(vc)
        return UINavigationController.init(rootViewController: vc)
    }
    
    // MARK: - PROPERTY
    
    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - UITableViewDelegate

extension CKRoomCreatingViewController: UITableViewDelegate {
    
}

// MARK: - UITableViewDataSource

extension CKRoomCreatingViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // sure to work
        guard let s = Section(rawValue: section) else { return 0 }
        
        // number rows in case
        switch s {
        case .option: return 2
        case .name: return 1
        case .topic: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = CKRoomBaseCell()        
        return cell
    }
    
}
