//
//  TweetCell.swift
//  TweeterTags
//
//  Created by Parth Parmar on 28/11/22.
//

import UIKit

class TweetTVCell : UITableViewCell {
    
    var tweet : TwitterTweet? {
        didSet {
            update()
        }
    }
    
    @IBOutlet weak var tweeterScreen: UILabel!
    @IBOutlet weak var tweeterText: UILabel!
    @IBOutlet weak var tweeterImage: UIImageView!
    @IBOutlet weak var tweeterDate: UILabel!
    
    
    func update() {
        
        tweeterScreen?.attributedText = nil
        tweeterText?.text = nil
        tweeterDate?.text = nil
        
        if( tweet == nil){
            return
        }
        
        //  var hashtags = [TwitterMention]()
        
        let hashtags = tweet?.hashtags
        let urls = tweet?.urls
        let mentions = tweet?.userMentions
        let attrString = NSMutableAttributedString(string: tweet!.text)
        
        tweeterScreen!.text = "\(tweet!.user)"
        tweeterScreen.font = UIFont(name:"Menlo", size: 12.0)
        let date = tweet!.created
        let TimeFormat = DateFormatter()
        TimeFormat.dateFormat = "HH:MM a"
        tweeterDate!.text = TimeFormat.string(from: date)
        
        for tag in hashtags!{
            let range = (tweet!.text as NSString).range(of: tag.keyword)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue , range: range)
        }
        for url in urls!{
            let range = (tweet!.text as NSString).range(of: url.keyword)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red , range: range)
        }
        for mention in mentions!{
            let range = (tweet!.text as NSString).range(of: mention.keyword)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.green , range: range)
        }
        
        tweeterText!.attributedText = attrString
        
        
    }
    
   
    }

