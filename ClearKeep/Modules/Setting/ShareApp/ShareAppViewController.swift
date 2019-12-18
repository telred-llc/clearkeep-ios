//
//  ShareAppViewController.swift
//  Riot
//
//  Created by ReasonLeveing on 12/18/19.
//  Copyright © 2019 matrix.org. All rights reserved.
//

import UIKit

class ShareAppViewController: MXKViewController {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionLabel.text = CKLocalization.string(byKey: "share_app_description")
        shareButton.setTitle(CKLocalization.string(byKey: "share_app_button_now"), for: .normal)
        dismissButton.setTitle(CKLocalization.string(byKey: "share_app_button_will_later"), for: .normal)
        
        themeService.typeStream.asObservable().subscribe { (theme) in
            
            let lightTheme = theme.element == ThemeType.light
            self.logoImageView.image = lightTheme ? #imageLiteral(resourceName: "logo_login_light") : #imageLiteral(resourceName: "logo_login_dark")
            self.view.backgroundColor = themeService.attrs.primaryBgColor
            
            self.descriptionLabel.textColor = themeService.attrs.navBarTintColor
            
            self.shareButton.setBackgroundImage(lightTheme ? #imageLiteral(resourceName: "btn_start_room_light") : #imageLiteral(resourceName: "btn_start_room_dark"), for: .normal)
            self.dismissButton.setTitleColor( themeService.attrs.primaryTextColor, for: .normal)
            
        }.disposed(by: disposeBag)
    }

    @IBAction func shareAction(_ sender: Any) {
        
        let urlString = CKEnvironment.target.serviceURL + "/api/share/get-deep-link?url=app://account"
        guard let url = URL(string: urlString) else { return }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func dismissAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
}
