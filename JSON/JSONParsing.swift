//
//  JSONParsing.swift
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name Kevin Tatroe nor the names of its contributors may be
 used to endorse or promote products derived from this software without
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation


public typealias JSONObject = [String : AnyObject]


/// Options for parsing and validating JSON using the `JSONParser` class.
public struct JSONParsingOptions : OptionSetType {
    public let rawValue: Int
    
    /// No options set.
    static let none = JSONParsingOptions(rawValue: 0)
    
    /// Allow empty values (will be converted to a default value when parsed).
    static let allowEmpty = JSONParsingOptions(rawValue: 1)
    
    /// Allow value conversion; for example, if bare literal instead of requested array, convert to an array containing it.
    static let allowConversion = JSONParsingOptions(rawValue: 2)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}


/**
 Normalizes values from JSON objects, with options for allowing for conversion from unexpected value
 types and missing values.
*/
public class JSONParser {
    public static func parseIdentifier(value: AnyObject?, options: JSONParsingOptions = .none) -> String? {
        if let stringValue = JSONParser.parseString(value) {
            return stringValue.lowercaseString
        }
        
        return nil
    }
    
    public static func parseString(value: AnyObject?, options: JSONParsingOptions = .none) -> String? {
        if let stringValue = value as? String {
            return stringValue.stringByDecodingJavascriptEntities()
        }
        
        if options.contains(.allowConversion) {
            if let numberValue = value as? NSNumber {
                return String(numberValue)
            }
        }
        
        if options.contains(.allowEmpty) {
            return ""
        }
        
        return nil
    }
    
    public static func parseInt(value: AnyObject?, options: JSONParsingOptions = .none) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        
        if options.contains(.allowConversion) {
            if let numberValue = value as? NSNumber {
                return Int(numberValue)
            }
            
            if let stringValue = value as? String {
                return Int(stringValue)
            }
        }
        
        if options.contains(.allowEmpty) {
            return 0
        }
        
        return nil
    }
    
    public static func parseDouble(value: AnyObject?, options: JSONParsingOptions = .none) -> Double? {
        if let doubleValue = value as? Double {
            return doubleValue
        }
        
        if options.contains(.allowConversion) {
            if let numberValue = value as? NSNumber {
                return Double(numberValue)
            }
            
            if let stringValue = value as? String {
                return Double(stringValue)
            }
        }
        
        if options.contains(.allowEmpty) {
            return 0.0
        }
        
        return nil
    }
    
    public static func parseBool(value: AnyObject?, options: JSONParsingOptions = .none) -> Bool? {
        if let boolValue = value as? Bool {
            return boolValue
        }
        
        if options.contains(.allowConversion) {
            if let numberValue = value as? NSNumber {
                return Bool(numberValue)
            }
            
            if let stringValue = value as? String {
                if stringValue.lowercaseString == "true" || stringValue == "1" {
                    return true
                }
                
                return false
            }
        }
        
        if options.contains(.allowEmpty) {
            return false
        }
        
        return nil
    }
    
    public static func parseArray(value: AnyObject?, options: JSONParsingOptions = .none) -> [AnyObject]? {
        if let arrayValue = value as? [AnyObject] {
            return arrayValue
        }
        
        if let value = value {
            if let _ = value as? NSNull {
                if options.contains(.allowConversion) {
                    return [AnyObject]()
                }
            }
            
            if options.contains(.allowConversion) {
                return [value]
            }
        }
        
        if options.contains(.allowEmpty) {
            return [AnyObject]()
        }
        
        return nil
    }
    
    public static func parseObject(value: AnyObject?, options: JSONParsingOptions = .none) -> JSONObject? {
        if let objectValue = value as? [String : AnyObject] {
            return objectValue
        }
        
        if let value = value {
            if let _ = value as? NSNull {
                if options.contains(.allowConversion) {
                    return [String : AnyObject]()
                }
            }
        }
        
        if options.contains(.allowEmpty) {
            return [String : AnyObject]()
        }
        
        return nil
    }
    
    public static func parseISO8601Date(value: AnyObject?, options: JSONParsingOptions = .none) -> NSDate? {
        if let dateString = JSONParser.parseString(value, options: options) {
            if let dateValue = NSDate.dateFromISO8601String(dateString) {
                return dateValue
            }
        }
        
        if options.contains(.allowEmpty) {
            return NSDate()
        }
        
        return nil
    }
}

public protocol JSONParsing {
    func updateFromJSONRepresentation(data: JSONObject)
    
    static func isValidJSONRepresentation (data: JSONObject) -> Bool
}


extension String {
    func stringByDecodingJavascriptEntities() -> String {
        func decodeHexValue(string: String, base: Int32) -> Character? {
            let code = UInt32(strtoul(string, nil, base))
            
            return Character(UnicodeScalar(code))
        }
        
        func decodeEntity(entity: String) -> Character? {
            if entity.hasPrefix("\\x") || entity.hasPrefix("\\u") {
                return decodeHexValue(entity.substringFromIndex(entity.startIndex.advancedBy(2)), base: 16)
            }
            
            return nil
        }
        
        var result = ""
        var position = startIndex
        
        let entityBeacons = ["\\x", "\\u"]
        
        for beacon in entityBeacons {
            while let entityRange = self.rangeOfString(beacon, range: position ..< endIndex) {
                result += self[position ..< entityRange.startIndex]
                position = entityRange.startIndex
                
                let entityLength = (beacon == "\\u") ? 4 : 2
                let entity = self[position ..< position.advancedBy(entityLength)]
                
                if let decodedEntity = decodeEntity(entity) {
                    result.append(decodedEntity)
                }
                else {
                    result.appendContentsOf(entity)
                }
            }
        }
        
        result += self[position ..< endIndex]
        
        return result
    }
}


extension NSDate {
    struct ISO8601Support {
        static let formatter: NSDateFormatter = {
            let formatter = NSDateFormatter()
            formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)
            formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            
            return formatter
        }()
    }
    
    public static func dateFromISO8601String(string: String) -> NSDate? {
        return ISO8601Support.formatter.dateFromString(string)
    }

    public var iso8601String: String { return ISO8601Support.formatter.stringFromDate(self) }
}
