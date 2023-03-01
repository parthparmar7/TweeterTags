//
//  MentionTVC.swift
//  TweeterTags
//
//  Created by Parth Parmar on 01/12/22.
//

import UIKit

class MentionTVC : UITableViewController {
    
    var tweet : TwitterTweet?
    let types = ["Image", "URL", "Hashtag", "User"]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.title = tweet?.user.name
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.types.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.section == 1){
            if let url = URL(string: (tweet?.urls[indexPath.row].keyword)!) {
                UIApplication.shared.open(url as URL)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return (tweet?.media.count)!
        case 1:
            return (tweet?.urls.count)!
        case 2:
            return (tweet?.hashtags.count)!
        case 3:
            return (tweet?.userMentions.count)!
        default:
            return 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            if((tweet?.media.count)! > 0){
                return self.types[section]
            } else {
                return ""
            }
        } else if (section == 1) {
            if((tweet?.urls.count)! > 0){
                return self.types[section]
            } else {
                return ""
            }
        } else if (section == 2) {
            if((tweet?.hashtags.count)! > 0){
                return self.types[section]
            } else {
                return ""
            }
        } else if (section == 3 ) {
            if((tweet?.userMentions.count)! > 0){
                return self.types[section]
            } else {
                return ""
            }
        }
        return ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section{
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell",for: indexPath) as! imageCell
            
            if let url:URL = tweet?.media[indexPath.row].url{
                print(url.absoluteString)
                cell.imageView?.load2(url: url)
                // cell.setNeedsLayout()
            }
            
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "urlCell",for: indexPath) as! urlCell
            cell.textLabel?.text = tweet!.urls[indexPath.row].keyword //2nd cell
            print(tweet!.urls[indexPath.row].keyword)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "hashtagCell",for: indexPath) as! hashtagCell
            cell.textLabel?.text = tweet!.hashtags[indexPath.row].keyword //3rd cell
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "userCell",for: indexPath) as! userCell
            cell.textLabel?.text = tweet!.userMentions[indexPath.row].keyword //4th cell
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "urlCell",for: indexPath) as! urlCell
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 0){
            return CGFloat(200)
        } else {
            return UITableView.automaticDimension
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mediaCall = sender as? hashtagCell {
            if segue.identifier == "hash"{
                if let destination =  segue.destination as? TweetsTVC{
                    if self.tableView.indexPathForSelectedRow != nil{
                        destination.twitterQueryText = (mediaCall.textLabel?.text)!
                    }
                }
            }
        } else if let mediaCall = sender as? userCell {
            if segue.identifier == "mention"{
                if let destination =  segue.destination as? TweetsTVC{
                    if self.tableView.indexPathForSelectedRow != nil{
                        destination.twitterQueryText = (mediaCall.textLabel?.text)!
                    }
                }
            }
        }
    }
        
        
    
}

extension UIImageView {
     func load2(url: URL) {
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

