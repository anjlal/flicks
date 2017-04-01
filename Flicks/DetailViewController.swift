//
//  DetailViewController.swift
//  Flicks
//
//  Created by Angie Lal on 3/31/17.
//  Copyright © 2017 Angie Lal. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var posterImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var overviewLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var infoView: UIView!
    var flick: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)
        let title = flick["title"] as? String
        titleLabel.text = title
        
        let overview = flick["overview"] as? String
        overviewLabel.text = overview
        
        overviewLabel.sizeToFit()
        
        if let posterPath = flick["poster_path"] as? String {
            let baseURL = "https://image.tmdb.org/t/p/w342"
            let imageURL = NSURL(string:baseURL + posterPath)
            posterImageView.setImageWith(imageURL as! URL)
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.

        // Pass the selected object to the new view controller.
    }
    */

}
