//
//  Fotka.h
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 08.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDataXMLNode.h"

@interface Fotka : NSObject <NSCoding>

@property(nonatomic) NSString *src;
@property(nonatomic) NSDate *date;
@property(nonatomic) NSString *authorName;
@property(nonatomic) NSURL *filePath;
@property(nonatomic) BOOL required;

+ (instancetype)null;
- (instancetype)initWithEntry:(GDataXMLElement *)entry;
- (BOOL)isNull;

@end
