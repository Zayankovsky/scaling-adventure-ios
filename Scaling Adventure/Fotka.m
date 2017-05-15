//
//  Fotka.m
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 08.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import "Fotka.h"

@implementation Fotka

@synthesize src, date, authorName, filePath, required;

+ (instancetype)null
{
    Fotka *image = [[self alloc] init];
    if (image) {
        image.filePath = nil;
    }
    return image;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.src = [coder decodeObjectForKey:@"src"];
        self.date = [coder decodeObjectForKey:@"date"];
        self.authorName = [coder decodeObjectForKey:@"authorName"];
        self.filePath = [coder decodeObjectForKey:@"filePath"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.src forKey:@"src"];
    [coder encodeObject:self.date forKey:@"date"];
    [coder encodeObject:self.authorName forKey:@"authorName"];
    [coder encodeObject:self.filePath forKey:@"filePath"];
}

- (instancetype)initWithEntry:(GDataXMLElement *)entry
{
    self = [super init];
    if (self) {
        GDataXMLElement *author = [entry elementsForName:@"author"][0];
        GDataXMLElement *name = [author elementsForName:@"name"][0];
        GDataXMLElement *uid = [author elementsForName:@"f:uid"][0];
        GDataXMLElement *content = [entry elementsForName:@"content"][0];
        GDataXMLElement *podDate = [entry elementsForName:@"f:pod-date"][0];

        self.src = [content attributeForName:@"src"].stringValue;
        self.date = [[[self class] dateFormatter] dateFromString:podDate.stringValue];
        self.authorName = name.stringValue;
        self.filePath = [self imageDestinationByAuthor:name.stringValue uid:uid.stringValue];
        self.required = NO;
    }
    return self;
}

- (BOOL)isNull
{
    return !filePath;
}

- (NSURL *)imageDestinationByAuthor:(NSString *)author uid:(NSString *)uid
{
    NSURL *path = [[[self class] cachesDirectory] URLByAppendingPathComponent:author];
    [[NSFileManager defaultManager] createDirectoryAtURL:path
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
    return [path URLByAppendingPathComponent:uid];
}

+ (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });

    return dateFormatter;
}

+ (NSURL *)cachesDirectory
{
    static NSURL *directory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        directory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                           inDomain:NSUserDomainMask
                                                  appropriateForURL:nil
                                                             create:YES
                                                              error:nil];
    });
    
    return directory;
}

@end
