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
import AVFoundation

class FlicksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var networkErrorLabel: UILabel!
    
    @IBOutlet weak var networkErrorImage: UIImageView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var flicks: [NSDictionary]?
    
    var endpoint: String?
    var searchActive : Bool = false
    var filteredData: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        self.tableView.backgroundColor = UIColor.white
        searchBar.delegate = self
        
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
        collectionView.insertSubview(refreshControl, at: 0)

        collectionView.isHidden = false
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
                self.networkErrorImage.image = UIImage(named: "network_error")
                self.networkErrorView.isHidden = false

            } else if let data = data,
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                self.networkErrorView.isHidden = true
                self.flicks = dataDictionary["results"] as? [NSDictionary]
                self.tableView.reloadData()
                self.collectionView.reloadData()
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
                self.networkErrorImage.image = UIImage(named: "network_error")
                self.networkErrorView.isHidden = false
            } else if let data = data,
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                self.networkErrorView.isHidden = true
                self.flicks = dataDictionary["results"] as? [NSDictionary]
                self.tableView.reloadData()
            }
            // ... Use the new data to update the data source ...
            
            // Reload the tableView now that there is new data
            self.tableView.reloadData()
            self.collectionView.reloadData()
            
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
        
        if(searchActive) {
            return (filteredData?.count)!
        }
        if let flicks = flicks {
            return flicks.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FlickCell", for: indexPath) as! FlickCell
        let flick = searchActive ? filteredData?[indexPath.row] : flicks![indexPath.row]

        let title = flick?["title"] as! String
        let overview = flick?["overview"] as! String
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        if let posterPath = flick?["poster_path"] as? String {
            let baseURL = "https://image.tmdb.org/t/p/w342"
            let imageURL = NSURLRequest(url: NSURL(string: baseURL + posterPath) as! URL)
          
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
    
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredData is the same as the original data
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
  
        if (searchText.isEmpty) {
            filteredData = flicks
        } else {
            filteredData = flicks?.filter { String(describing: $0["title"]).range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
            }
        }
        if(filteredData?.count == 0){
            searchActive = false
        } else {
            searchActive = true
        }
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
        searchActive = true

    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell: FlickCell = tableView.cellForRow(at: indexPath) as! FlickCell
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.5)
        cell.selectedBackgroundView = backgroundView
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if(searchActive) {
            return (filteredData?.count)!
        }
        
        if let flicks = flicks {
            return flicks.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "com.codepath.CollectionViewCell", for: indexPath) as! CollectionViewCell
        print(indexPath.row)
        let flick = searchActive ? filteredData?[indexPath.row] : flicks?[indexPath.row]
        
        if let posterPath = flick?["poster_path"] as? String {
            let baseURL = "https://image.tmdb.org/t/p/w342"
            let imageURL = NSURLRequest(url: NSURL(string: baseURL + posterPath) as! URL)
    
            
            cell.posterImage.setImageWith(
                imageURL as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Image was NOT cached, fade in image")
                        cell.posterImage.alpha = 0.0
                        cell.posterImage.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.posterImage.alpha = 1.0
                        })
                    } else {
                        print("Image was cached so just update the image")
                        cell.posterImage.image = image
                    }
            },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
            })
        }
        
        return cell
    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        selectedRow = indexPath.row
//        self.performSegue(withIdentifier: "collectionSegue", sender: self)
//        
//    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller
        let detailViewController = segue.destination as! DetailViewController
        
        if (segue.identifier == "collectionSegue") {
            let cell = sender as! UICollectionViewCell
            let indexPath = collectionView.indexPath(for: cell)
            let flick = flicks![(indexPath?.row)!]
            detailViewController.flick = flick

        } else {
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let flick = searchActive ? filteredData?[(indexPath?.row)!] : flicks![(indexPath?.row)!]
        // Pass the selected object to the new view controller.
            detailViewController.flick = flick

        
       }

    }
}
