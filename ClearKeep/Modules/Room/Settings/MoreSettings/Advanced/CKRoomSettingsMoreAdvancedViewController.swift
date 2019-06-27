//
//  CKRoomSettingsMoreAdvancedViewController.swift
//  Riot
//
//  Created by Sinbad Flyce on 2/21/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import Foundation

final class CKRoomSettingsMoreAdvancedViewController: MXKViewController {
    
    // MARK: - OUTLET
    
    @IBOutlet weak var tableView: UITableView!
    
    // ENUM
    
    private enum Section: Int {
        case info = 0
        case version = 1
        static func count() -> Int { return 2 }
    }

    // MARK: - PROPERTY
    
    public var mxRoom: MXRoom!
    private let disposeBag = DisposeBag()

    // MARK: - OVERRIDE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(CKRoomSettingsMoreAdvancedCell.nib, forCellReuseIdentifier: CKRoomSettingsMoreAdvancedCell.identifier)
        self.navigationItem.title = "Advanced"
        self.bindingTheme()
    }
    
    // MARK: - PRIVATE

    private func bindingTheme() {
        // Binding navigation bar color
        themeService.attrsStream.subscribe(onNext: { [weak self] (theme) in
            self?.defaultBarTintColor = themeService.attrs.primaryBgColor
            self?.barTitleColor = themeService.attrs.primaryTextColor
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        themeService.rx
            .bind({ $0.secondBgColor }, to: view.rx.backgroundColor, tableView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    private func cellForAdvanced(_ indexPath: IndexPath) -> CKRoomSettingsMoreAdvancedCell {
        let cell = self.tableView.dequeueReusableCell(
            withIdentifier: CKRoomSettingsMoreAdvancedCell.identifier,
            for: indexPath) as! CKRoomSettingsMoreAdvancedCell
        
        cell.selectionStyle = .none
        
        let s = Section(rawValue: indexPath.section)!
        switch s {
        case .info:
            cell.title = self.mxRoom?.roomId ?? "Unknown"
        case .version:
            cell.title = "Version: 1"
        }

        cell.titleLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
        cell.theme.backgroundColor = themeService.attrStream{ $0.secondBgColor }

        return cell
    }
    
    private func titleForSection(_ section: Int ) -> String {
        let s = Section(rawValue: section)!
        
        switch s {
        case .info:
            return "ROOM ID"
        case .version:
            return "ROOM VERSION"
        }
    }
    
    // MARK: - PUBLIC
}

extension CKRoomSettingsMoreAdvancedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CKLayoutSize.Table.defaultHeader
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = CKRoomHeaderInSectionView.instance() {
            view.descriptionLabel.text = self.titleForSection(section)
            view.descriptionLabel.theme.textColor = themeService.attrStream{ $0.primaryTextColor }
            view.theme.backgroundColor = themeService.attrStream{ $0.tblHeaderBgColor }
            return view
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

extension CKRoomSettingsMoreAdvancedViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.cellForAdvanced(indexPath)
    }
    
}
