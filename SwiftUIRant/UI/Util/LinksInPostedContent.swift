//
//  LinksInPostedContent.swift
//  SwiftUIRant
//
//  Created by Wilhelm Oks on 04.11.22.
//

import Foundation
import SwiftDevRant

extension AttributedString {
    static func from(postedContent: String, links: [Link]?) -> AttributedString {
        var result = AttributedString(stringLiteral: postedContent)
        
        links?.forEach { link in
            if let range = range(of: link, in: result) {
                switch link.kind {
                case .url:
                    result[range].foregroundColor = .primaryForeground
                    result[range].underlineStyle = .single
                    result[range].link = rantUrl(link: link.url)
                case .userMention:
                    result[range].foregroundColor = .primary
                    result[range].font = .baseSize(16).bold()
                    result[range].swiftUI.font = .baseSize(16).bold()
                    result[range].link = mentionUrl(userId: link.url)
                }
            }
        }
        
        return result
    }
    
    fileprivate static func range(of link: Link, in string: AttributedString) -> Range<AttributedString.Index>? {
        var range: Range<AttributedString.Index>?
        
        if let start = link.start, let end = link.end {
            let nsRange = NSRange(location: start, length: end - start)
            range = Range<AttributedString.Index>(nsRange, in: string)
        }
        
        if range == nil {
            let nsRange = (String(string.characters) as NSString).range(of: link.title)
            range = Range<AttributedString.Index>(nsRange, in: string)
        }
        
        return range
    }
    
    fileprivate static func rantUrl(link: String) -> URL? {
        let rantPrefix = "https://devrant.com/rants/"
        if link.hasPrefix(rantPrefix) {
            // A rant link looks like this:
            // https://devrant.com/rants/<rant-id>/first-few-letters-of-rant-content
            // Convert it into this:
            // joydev://rant/<rant-id>
            // so that it can be opened in this app.
            let withCustomScheme = link.replacing(rantPrefix, with: "joydev://rant/")
            let components = withCustomScheme.split(separator: "/", omittingEmptySubsequences: false)
            let joinedUntilRantId = components.prefix(upTo: 4).joined(separator: "/")
            return URL(string: joinedUntilRantId)
        } else {
            return URL(string: link)
        }
    }
    
    private static func mentionUrl(userId: String) -> URL? {
        return URL(string: "joydev://profile/\(userId)")
    }
}

private struct LinkReplaceInfo {
    let range: Range<AttributedString.Index>
    let url: String
}

extension String {
    func devRant(resolvingLinks links: [Link]?) -> String {
        guard let links else { return self }
        
        var result = AttributedString(stringLiteral: self)
        
        let replaceInfos: [LinkReplaceInfo] = links.compactMap { link -> LinkReplaceInfo? in
            guard let range = AttributedString.range(of: link, in: result) else { return nil }
            
            switch link.kind {
            case .url:
                guard let url = AttributedString.rantUrl(link: link.url)?.absoluteString else { return nil }
                return LinkReplaceInfo(range: range, url: url)
            case .userMention:
                return nil
            }
        }
        
        // sorted from last to first so that it won't break the ranges when replacing strings.
        let sortedReplaceInfos = replaceInfos.sorted { (lhs, rhs) in
            return lhs.range.lowerBound > rhs.range.lowerBound
        }
        
        for replaceInfo in sortedReplaceInfos {
            result.replaceSubrange(replaceInfo.range, with: AttributedString(replaceInfo.url))
        }
        
        return String(result.characters)
    }
}
