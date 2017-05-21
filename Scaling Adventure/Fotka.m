//
//  Fotka.m
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 08.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import "Fotka.h"

#import "math.h"

@interface Fotka ()

@property NSMutableDictionary<NSNumber *, NSString *> *hrefs;

@end

@implementation Fotka

@synthesize hrefs, date, authorName, filePath, size, required;

+ (instancetype)null
{
    Fotka *image = [[self alloc] init];
    if (image) {
        image.filePath = nil;
        image.required = NO;
    }
    return image;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.hrefs = [coder decodeObjectForKey:@"hrefs"];
        self.date = [coder decodeObjectForKey:@"date"];
        self.authorName = [coder decodeObjectForKey:@"authorName"];
        self.filePath = [coder decodeObjectForKey:@"filePath"];
        self.size = [coder decodeFloatForKey:@"size"];
        self.required = NO;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.hrefs forKey:@"hrefs"];
    [coder encodeObject:self.date forKey:@"date"];
    [coder encodeObject:self.authorName forKey:@"authorName"];
    [coder encodeObject:self.filePath forKey:@"filePath"];
    [coder encodeFloat:self.size forKey:@"size"];
}

- (instancetype)initWithEntry:(GDataXMLElement *)entry
{
    self = [super init];
    if (self) {
        GDataXMLElement *author = [entry elementsForName:@"author"][0];
        GDataXMLElement *name = [author elementsForName:@"name"][0];
        GDataXMLElement *uid = [author elementsForName:@"f:uid"][0];
        GDataXMLElement *podDate = [entry elementsForName:@"f:pod-date"][0];
        
        self.hrefs = [NSMutableDictionary dictionary];
        for (GDataXMLElement *img in [entry elementsForName:@"f:img"]) {
            double height = [img attributeForName:@"height"].stringValue.doubleValue;
            double width = [img attributeForName:@"width"].stringValue.doubleValue;
            NSString *href = [img attributeForName:@"href"].stringValue;
            self.hrefs[[NSNumber numberWithDouble:fmin(height, width)]] = href;
        }

        self.date = [[[self class] dateFormatter] dateFromString:podDate.stringValue];
        self.authorName = name.stringValue;
        self.filePath = [self imageDestinationByAuthor:name.stringValue uid:uid.stringValue];
        self.size = -1;
        self.required = NO;
    }
    return self;
}

- (BOOL)isNull
{
    return !filePath;
}

- (NSString *)href
{
    double bestSize = -1;
    for (NSNumber *availableSize in hrefs) {
        if (bestSize < size) {
            if (availableSize.doubleValue > bestSize) {
                bestSize = availableSize.doubleValue;
            }
        } else if (bestSize > size) {
            if (size <= availableSize.doubleValue && availableSize.doubleValue < bestSize) {
                bestSize = availableSize.doubleValue;
            }
        } else {
            break;
        }
    }
    
    return hrefs[[NSNumber numberWithDouble:bestSize]];
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
