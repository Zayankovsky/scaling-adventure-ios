//
//  Fotka.h
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 08.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Fotka : NSObject

@property(nonatomic) NSString *url;
@property(nonatomic) NSURL *filePath;
@property(nonatomic) BOOL required;

@end
