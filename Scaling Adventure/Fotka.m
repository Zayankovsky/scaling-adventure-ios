//
//  Fotka.m
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 08.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import "Fotka.h"

@implementation Fotka

@synthesize src, author, filePath, required;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.src = [coder decodeObjectForKey:@"src"];
        self.author = [coder decodeObjectForKey:@"author"];
        self.filePath = [coder decodeObjectForKey:@"filePath"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.src forKey:@"src"];
    [coder encodeObject:self.author forKey:@"author"];
    [coder encodeObject:self.filePath forKey:@"filePath"];
}

@end
