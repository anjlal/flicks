//
//  FlicksViewController.swift
//  Flicks
//
//  Created by Angie Lal on 3/30/17.
//  Copyright © 2017 Angie Lal. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class FlicksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var networkErrorLabel: UILabel!
    
    var flicks: [NSDictionary]?
    
    var endpoint: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.tintColor = UIColor.white
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        }
        
        networkErrorView.isHidden = true
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(FlicksViewController.refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        // add refresh control to table view
        tableView.insertSubview(refreshControl, at: 0)
        //tableView.insertSubview(refreshControl, at: 0)

        
        tableView.dataSource = self
        tableView.delegate = self

        // Do any additional setup after loading the view.
        
        let apiKey = valueForAPIKey(named:"API_SECRET")
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        // Display HUD right before the request is made
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            // Hide HUD once the network request comes back (must be done on main UI thread)
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if error != nil {
                self.networkErrorLabel.text = "Network Error"
                let attachment: NSTextAttachment = NSTextAttachment()
                attachment.image = UIImage(named: "network_error")

                let attachmentString: NSAttributedString = NSAttributedString(attachment: attachment)
                let strLabelText: NSAttributedString = NSAttributedString(string: self.networkErrorLabel.text!)
                let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attachmentString)
                mutableAttachmentString.append(strLabelText)
                
                self.networkErrorLabel.attributedText = mutableAttachmentString
                
                self.networkErrorView.isHidden = false

            } else if let data = data,
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                self.networkErrorView.isHidden = true
                self.flicks = dataDictionary["results"] as? [NSDictionary]
                self.tableView.reloadData()
               //print(dataDictionary)
            }
        }
        task.resume()
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshControlAction(_ refreshControl: UIRefreshControl) {
        
        // ... Create the URLRequest `myRequest` ...
        let apiKey = valueForAPIKey(named:"API_SECRET")
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)


        
        // Configure session so that completion handler is executed on main UI thread
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if error != nil {
                self.networkErrorLabel.text = "Network Error"
                let attachment: NSTextAttachment = NSTextAttachment()
                attachment.image = UIImage(named: "network_error")
                let attachmentString: NSAttributedString = NSAttributedString(attachment: attachment)
                let strLabelText: NSAttributedString = NSAttributedString(string: self.networkErrorLabel.text!)
                let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attachmentString)
                mutableAttachmentString.append(strLabelText)
                
                self.networkErrorLabel.attributedText = mutableAttachmentString
                self.networkErrorView.isHidden = false
            } else if let data = data,
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                //print(dataDictionary)
                self.networkErrorView.isHidden = true
                self.flicks = dataDictionary["results"] as? [NSDictionary]
                self.tableView.reloadData()
            }
            // ... Use the new data to update the data source ...
            
            // Reload the tableView now that there is new data
            self.tableView.reloadData()
            
            // Tell the refreshControl to stop spinning
            refreshControl.endRefreshing()
        }
        task.resume()
    }
    
    func valueForAPIKey(named keyname:String) -> String {
        // Credit to the original source for this technique at
        // http://blog.lazerwalker.com/blog/2014/05/14/handling-private-api-keys-in-open-source-ios-apps
        let filePath = Bundle.main.path(forResource: "ApiKeys", ofType: "plist")
        let plist = NSDictionary(contentsOfFile:filePath!)
        let value = plist?.object(forKey: keyname) as! String
        return value
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let flicks = flicks {
            return flicks.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FlickCell", for: indexPath) as! FlickCell
        let flick = flicks![indexPath.row]
        let title = flick["title"] as! String
        let overview = flick["overview"] as! String
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        if let posterPath = flick["poster_path"] as? String {
            let baseURL = "https://image.tmdb.org/t/p/w342"
            //let imageURL = NSURL(string:baseURL + posterPath)
            let imageURL = NSURLRequest(url: NSURL(string: baseURL + posterPath) as! URL)
            //cell.posterView.setImageWith(imageURL as! URL)
          
            cell.posterView.setImageWith(
                imageURL as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Image was NOT cached, fade in image")
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.posterView.alpha = 1.0
                        })
                    } else {
                        print("Image was cached so just update the image")
                        cell.posterView.image = image
                    }
            },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
            })
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell: FlickCell = tableView.cellForRow(at: indexPath) as! FlickCell
//        if(cell.isSelected){
//            cell.selectionStyle = .none
//            
//            // Use a red color when the user selects the cell
//            let backgroundView = UIView()
//            backgroundView.backgroundColor = UIColor.red
//            cell.selectedBackgroundView = backgroundView
//
//        }else{
//            cell.backgroundColor = UIColor.clear
//        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let flick = flicks?[(indexPath?.row)!]
        // Get the new view controller
        let detailViewController = segue.destination as! DetailViewController
        // Pass the selected object to the new view controller.
        detailViewController.flick = flick

    }
 

}
