//
//  TwitterAPI.swift
//

import Foundation
import TwitterKit
import CoreLocation

// MARK: - TwitterAPI 1.1

struct TwitterAPI {
    struct User {
        static let name = "name"
        static let screenName = "screen_name"
        static let id = "id_str"
        static let verified = "verified"
        static let profileImageURL = "profile_image_url"
    }
    
    struct Tweet {
        static let user = "user"
        static let text = "text"
        static let created = "created_at"
        static let id = "id_str"
        static let media = "entities.media"
    }
    
    struct Entities {
        static let hashtags = "entities.hashtags"
        static let urls = "entities.urls"
        static let userMentions = "entities.user_mentions"
        static let indices = "indices"
        static let text = "text"
    }
    
    struct Media {
        static let url = "media_url_https"
        static let width = "sizes.small.w"
        static let height = "sizes.small.h"
    }
    
    struct Constants {
        static let jsonExtension = ".json"
        static let urlPrefix = "https://api.twitter.com/1.1/"
    }
    
    struct Request {
        static let count = "count"
        static let query = "q"
        static let tweets = "statuses"
        static let resultType = "result_type"
        static let resultTypeRecent = "recent"
        static let resultTypePopular = "popular"
        static let geocode = "geocode"
        static let searchForTweets = "search/tweets"
        static let maxID = "max_id"
        static let sinceID = "since_id"
        struct SearchMetadata {
            static let maxID = "search_metadata.max_id_str"
            static let nextResults = "search_metadata.next_results"
            static let separator = "&"
        }
    }
    
    static let twitterDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// MARK: - Twitter User

public typealias PropertyList = Any

public struct TwitterUser: CustomStringConvertible
{
    public var description: String { return "@\(screenName) (\(name))\(verified ? " ✅" : "")" }
    public let screenName: String
    public let name: String
    public let id: String
    public let verified: Bool
    public let profileImageURL: URL?
    
    public init?(_ json: [String: PropertyList]) {
        guard let screenName = json[TwitterAPI.User.screenName] as? String,
              let name = json[TwitterAPI.User.name] as? String,
              let id = json[TwitterAPI.User.id] as? String
        else { return nil }
        
        self.screenName = screenName
        self.name = name
        self.id = id
        
        self.verified = (json[TwitterAPI.User.verified] as? NSNumber)?.boolValue ?? false
        let urlString = (json[TwitterAPI.User.profileImageURL] as? String) ?? ""
        self.profileImageURL = (urlString.count > 0) ? URL(string: urlString) : nil
    }
    
    public var plist: PropertyList {
        [ TwitterAPI.User.name: name,
          TwitterAPI.User.screenName: screenName,
          TwitterAPI.User.id: id,
          TwitterAPI.User.verified: verified,
          TwitterAPI.User.profileImageURL: profileImageURL?.absoluteString ?? ""]
    }
}

// MARK: - Twitter Media

public struct TwitterMedia: CustomStringConvertible
{
    public var description: String { return "\(url.absoluteString) (aspect ratio = \(aspectRatio))" }
    public let url: URL
    public let aspectRatio: Double
    
    public init?(_ json: [String: PropertyList]) {
        guard let height = (json as NSDictionary).value(forKeyPath: TwitterAPI.Media.height) as? Double, height > 0,
              let width = (json as NSDictionary).value(forKeyPath: TwitterAPI.Media.width) as? Double, width > 0,
              let urlString = json[TwitterAPI.Media.url] as? String,
              let url = URL(string: urlString)
        else { return nil }
        self.url = url
        self.aspectRatio = width / height
    }
}


// MARK: - Twitter Tweet

public struct TwitterTweet: CustomStringConvertible {
    public var description: String { return "\(user) - \(created)\n\(text)\nhashtags: \(hashtags)\nurls: \(urls)\nuser_mentions: \(userMentions)" + "\nid: \(id)" }
    public let text: String
    public let user: TwitterUser
    public let created: Date
    public let id: String
    public let media: [TwitterMedia]
    public let hashtags: [TwitterMention]
    public let urls: [TwitterMention]
    public let userMentions: [TwitterMention]
    
    public init?(_ json: [String: PropertyList])
    {
        guard let userData = json[TwitterAPI.Tweet.user] as? [String: PropertyList],
              let user = TwitterUser(userData),
              let text = json[TwitterAPI.Tweet.text] as? String,
              let created = (json[TwitterAPI.Tweet.created] as? String)?.asTwitterDate,
              let id = json[TwitterAPI.Tweet.id] as? String
        else { return nil }
        
        self.user = user
        self.text = text
        self.created = created
        self.id = id
        
        let data = [TwitterAPI.Tweet.media, TwitterAPI.Entities.hashtags, TwitterAPI.Entities.urls, TwitterAPI.Entities.userMentions]
            .map { (json as NSDictionary).value(forKeyPath: $0) as? [PropertyList] }
        
        self.media = TwitterTweet.mediaItemsFrom(data[0])
        self.hashtags = TwitterTweet.mentionsFrom(data[1], in: text, with: "#")
        self.urls = TwitterTweet.mentionsFrom(data[2], in: text, with: "http")
        self.userMentions = TwitterTweet.mentionsFrom(data[3], in: text, with: "@")
    }
    
    // MARK: - Private API
    
    private static func mediaItemsFrom(_ json: [PropertyList]?) -> [TwitterMedia] {
        guard let twitterData = json as? [[String: PropertyList]] else { return [] }
        var mediaItems = [TwitterMedia]()
        for mediaItemData in twitterData {
            if let mediaItem = TwitterMedia(mediaItemData) { mediaItems.append(mediaItem) }
        }
        return mediaItems
    }
    
    private static func mentionsFrom(_ json: [PropertyList]?, in text: String, with prefix: String) -> [TwitterMention] {
        guard let twitterData = json as? [[String: PropertyList]] else { return [] }
        var mentions = [TwitterMention]()
        for mentionData in twitterData {
            if let mention = TwitterMention(mentionData, in: text, with: prefix) {
                mentions.append(mention)
            }
        }
        return mentions
    }
}

// MARK: - Twitter Mention

public struct TwitterMention: CustomStringConvertible
{
    public var description: String { return "\(keyword) (\(nsrange.location), \(nsrange.location+nsrange.length-1))" }
    public let keyword: String              // # or @ or http prefix
    public let nsrange: NSRange             // index into tweet's (Attributed)String
    
    public init?(_ json: [String: PropertyList], in text: String, with prefix: String)
    {
        guard let indices = json[TwitterAPI.Entities.indices] as? [Int],
              let start = indices.first, start >= 0,
              let end = indices.last, end > start
        else { return nil }
        
        var prefixAloneOrPrefixedMention = prefix
        if let mention = json[TwitterAPI.Entities.text] as? String {
            prefixAloneOrPrefixedMention = mention.prependPrefixIfAbsent(prefix)
        }
        let expectedRange = NSRange(location: start, length: end - start)
        guard let nsrange = text.rangeOfSubstringWithPrefix(prefixAloneOrPrefixedMention, expectedRange: expectedRange)
        else { return nil }
        
        self.keyword = (text as NSString).substring(with: nsrange)
        self.nsrange = nsrange
    }
}

// MARK: - Twitter request

public class TwitterRequest
{
    public let requestType: String
    public let parameters: [String: String]
    
    public init(_ requestType: String, _ parameters: [String: String] = [:]) {
        self.requestType = requestType
        self.parameters = parameters
    }
    
    public convenience init(search: String, count: Int = 0) {
        var parameters = [TwitterAPI.Request.query : search]
        if count > 0 { parameters[TwitterAPI.Request.count] = "\(count)" }
        self.init(TwitterAPI.Request.searchForTweets, parameters)
    }
        
    public func fetchTweets(_ handler: @escaping ([TwitterTweet]) -> Void) {
        fetch { results in
            var tweets = [TwitterTweet]()
            var tweetArray: [PropertyList]?
            if let dictionary = results as? [String: PropertyList] {
                if let tweets = dictionary[TwitterAPI.Request.tweets] as? [PropertyList] { tweetArray = tweets }
                else if let tweet = TwitterTweet(dictionary) { tweets = [tweet] }
            } else if let array = results as? [PropertyList] {
                tweetArray = array
            }
            if tweetArray != nil {
                for tweetData in tweetArray! {
                    if let json = tweetData as? [String : PropertyList], let tweet = TwitterTweet(json) {
                        tweets.append(tweet)
                    }
                }
            }
            handler(tweets)
        }
    }
        
    public func fetch(_ handler: @escaping (_ results: PropertyList?) -> Void) {
        performTwitterRequest(handler)
    }
    
    // Create request for older tweets
    public var requestForOlder: TwitterRequest? {
        if min_id == nil {
            if parameters[TwitterAPI.Request.maxID] != nil { return self }
        }
        else {
            return modifiedRequest(parametersToChange: [TwitterAPI.Request.maxID : min_id!])
        }
        return nil
    }
    
    // Create request for newer tweets
    public var requestForNewer: TwitterRequest? {
        if max_id == nil {
            if parameters[TwitterAPI.Request.sinceID] != nil { return self }
        }
        else {
            return modifiedRequest(parametersToChange: [TwitterAPI.Request.sinceID : max_id!], clearCount: true)
        }
        return nil
    }
    
    // MARK: - Private API
    private func performTwitterRequest(_ handler: @escaping (PropertyList?) -> Void) {
        let client = TWTRAPIClient()
        var clientError : NSError?
        let jsonExtension = (self.requestType.range(of: TwitterAPI.Constants.jsonExtension) == nil) ? TwitterAPI.Constants.jsonExtension : ""
        let request = client.urlRequest(withMethod: "GET", url: "\(TwitterAPI.Constants.urlPrefix)\(self.requestType)\(jsonExtension)", parameters: self.parameters, error: &clientError)
        
        client.sendTwitterRequest(request) { (response, responseData, error) -> Void in
            if let err = error { print("Error: \(err.localizedDescription)") }
            else {
                var pListResponse: PropertyList?
                if responseData != nil {
                    pListResponse = try! JSONSerialization.jsonObject(
                        with: responseData!,
                        options: JSONSerialization.ReadingOptions.mutableLeaves) as PropertyList?
                    if pListResponse == nil {
                        let error = "Couldn't parse JSON"
                        self.log(error as AnyObject)
                        pListResponse = error as PropertyList?
                    }
                } else {
                    let error = "Silence from Twitter."
                    self.log(error as AnyObject)
                    pListResponse = error as PropertyList?
                }
                self.synchronize { self.captureFollowonRequestInfo(pListResponse) }
                handler(pListResponse)
            }
        }
    }
    
    private var min_id: String? = nil
    private var max_id: String? = nil
    
    private func modifiedRequest(parametersToChange: Dictionary<String,String>, clearCount: Bool = false) -> TwitterRequest {
        var newParameters = parameters
        for (key, value) in parametersToChange {
            newParameters[key] = value
        }
        if clearCount { newParameters[TwitterAPI.Request.count] = nil }
        return TwitterRequest(requestType, newParameters)
    }
    
    private func captureFollowonRequestInfo(_ pListResponse: PropertyList?) {
        if let responseDict = pListResponse as? NSDictionary {
            self.max_id = responseDict.value(forKeyPath: TwitterAPI.Request.SearchMetadata.maxID) as? String
            if let next_results = responseDict.value(forKeyPath: TwitterAPI.Request.SearchMetadata.nextResults) as? String {
                for queryTerm in next_results.components(separatedBy: TwitterAPI.Request.SearchMetadata.separator) {
                    if queryTerm.hasPrefix("?\(TwitterAPI.Request.maxID)=") {
                        let next_id = queryTerm.components(separatedBy: "=")
                        if next_id.count == 2 {
                            self.min_id = next_id[1]
                        }
                    }
                }
            }
        }
    }
    
    private func log(_ whatToLog: AnyObject) { debugPrint("TwitterRequest: \(whatToLog)") }
    
    private func synchronize(_ closure: () -> Void) {
        objc_sync_enter(self)
        closure()
        objc_sync_exit(self)
    }
}

// MARK: - Class Extensions

fileprivate extension String {
    var asTwitterDate: Date? { TwitterAPI.twitterDateFormatter.date(from: self) }
}


fileprivate extension String {
    func prependPrefixIfAbsent(_ prefix: String) -> String {
        if hasPrefix(prefix) { return self }
        else { return prefix + self }
    }
}

fileprivate extension NSString
{
    func rangeOfSubstringWithPrefix(_ prefix: String, expectedRange: NSRange) -> NSRange?
    {
        var offset = 0
        var substringRange = expectedRange
        while range.contains(substringRange) && substringRange.intersects(expectedRange) {
            if substring(with: substringRange).hasPrefix(prefix) {
                return substringRange
            }
            offset = offset > 0 ? -(offset+1) : -(offset-1)
            substringRange.location += offset
        }
        
        var searchRange = range
        var bestMatchRange = NSRange.NotFound
        var bestMatchDistance = Int.max
        repeat {
            substringRange = self.range(of: prefix, options: [], range: searchRange)
            let distance = substringRange.distanceFrom(expectedRange)
            if distance < bestMatchDistance {
                bestMatchRange = substringRange
                bestMatchDistance = distance
            }
            searchRange.length -= substringRange.end - searchRange.start
            searchRange.start = substringRange.end
        } while searchRange.length > 0
        
        if bestMatchRange.location != NSNotFound {
            bestMatchRange.length = expectedRange.length
            if range.contains(bestMatchRange) {
                return bestMatchRange
            }
        }
        
        print("No keyword with prefix \(prefix) in range \(expectedRange) of \(self)")
        return nil
    }
    
    var range: NSRange { return NSRange(location:0, length: length) }
}

fileprivate extension NSRange
{
    func contains(_ range: NSRange) -> Bool {
        return range.location >= location && range.location+range.length <= location+length
    }
    
    func intersects(_ range: NSRange) -> Bool {
        if range.location == NSNotFound || location == NSNotFound {
            return false
        } else {
            return (range.start >= start && range.start < end) || (range.end >= start && range.end < end)
        }
    }
    
    func distanceFrom(_ range: NSRange) -> Int {
        if range.location == NSNotFound || location == NSNotFound {
            return Int.max
        } else if intersects(range) {
            return 0
        } else {
            return (end < range.start) ? range.start - end : start - range.end
        }
    }
    
    static let NotFound = NSRange(location: NSNotFound, length: 0)
    
    var start: Int {
        get { return location }
        set { location = newValue }
    }
    
    var end: Int { return location+length }
}



