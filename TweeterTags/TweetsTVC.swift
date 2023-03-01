//
//  TweetsTVC.swift
//  TweeterTags
//
//  Created by Parth Parmar on 27/11/22.
//

import UIKit

class TweetsTVC: UITableViewController,UITextFieldDelegate{
    
    
    @IBOutlet weak var twitterQueryTextField: UITextField!{
        didSet{
            twitterQueryTextField.delegate = self
            twitterQueryTextField.text = twitterQueryText
        }
    }

    
    var tweets = [[TwitterTweet]]()
    var twitterQueryText:String = "#ucd"{
        didSet{
            lastSuccessfulRequest = nil
            twitterQueryTextField?.text = twitterQueryText
            tweets.removeAll()
            tableView.reloadData()
            refresh()
        }
    }
    
    var lastSuccessfulRequest: TwitterRequest?
    
    var nextRequestToAttempt: TwitterRequest? {
        guard (lastSuccessfulRequest != nil) else {
            guard (twitterQueryTextField != nil) else {
                return nil
            }
            return TwitterRequest(search: twitterQueryText, count: 15)
        }
        return lastSuccessfulRequest!.requestForNewer
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tweets.count
    }
    
    func refresh(_ sender: UIRefreshControl?) {
        guard let request = nextRequestToAttempt else {
            sender?.endRefreshing()
            return
        }
        request.fetchTweets { (newTweets) -> Void in
            DispatchQueue.main.async { () -> Void in
                if newTweets.count > 0 {
                    self.lastSuccessfulRequest = request
                    self.tweets.insert(newTweets, at: 0)
                    self.tableView.reloadData()
                }
                sender?.endRefreshing()
            }
        }
    }
    
    func refresh() {
        refreshControl?.beginRefreshing()
        refresh(refreshControl)
    }
    
    override func viewDidLoad() {
        twitterQueryTextField.delegate = self
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        
        
        refresh()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        twitterQueryText = textField.text!
        twitterQueryTextField.resignFirstResponder()
        return true
    }
   
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TweeterCell", for: indexPath) as! TweetTVCell
        let tweet = tweets[indexPath.section][indexPath.row]
        let url = tweet.user.profileImageURL!
        
        cell.tweeterImage.load(url: url)
        
        //                URLSession.shared.dataTask(with: url) { (imageData, response, error) in
        //                    guard let imageData = imageData else { return }
        //                    DispatchQueue.main.async {
        //                        cell.imageView?.image = UIImage(data: imageData)
        //                          }
        //                }.resume()
        
        cell.tweet = tweets[indexPath.section][indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showInfo"{
            if let target =  segue.destination as? MentionTVC{
                if let index = self.tableView.indexPathForSelectedRow{
                    target.tweet = tweets[index.section][index.row]
                }
            }
        }
    }
    
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
