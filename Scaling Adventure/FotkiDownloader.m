//
//  FotkiDownloader.m
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 09.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import "FotkiDownloader.h"

#import <AFURLSessionManager.h>
#import "GDataXMLNode.h"

typedef void (^FeedCompletionHandler)(NSURLResponse *response, id responseObject, NSError *error);
typedef NSURL * (^Destination)(NSURL *targetPath, NSURLResponse *response);
typedef void (^ImageCompletionHandler)(NSURLResponse *, NSURL *, NSError *);

@interface FotkiDownloader ()

@property AFURLSessionManager *feedManager;
@property AFURLSessionManager *imageManager;
@property void (^downloadedFeedHandler)();
@property void (^downloadedImageHandler)(NSUInteger);
@property(nonatomic) NSMutableDictionary<NSNumber *, Fotka *> *images;

@end

@implementation FotkiDownloader

- (instancetype)initWithDownloadedFeedHandler:(void (^)())downloadedFeedHandler
                       downloadedImageHandler:(void (^)(NSUInteger))downloadedImageHandler {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

        AFHTTPResponseSerializer *atomXmlResponseSerializer = [AFHTTPResponseSerializer serializer];
        atomXmlResponseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/atom+xml"];

        self.feedManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        self.feedManager.responseSerializer = atomXmlResponseSerializer;

        self.imageManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        self.imageManager.responseSerializer = [AFImageResponseSerializer serializer];

        self.downloadedFeedHandler = downloadedFeedHandler;
        self.downloadedImageHandler = downloadedImageHandler;

        self.images = [NSMutableDictionary dictionaryWithCapacity:100];
    }
    return self;
}

- (void)downloadFeed:(NSString *)url {
    NSString *feedPath = [self feedDestination].path;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    FeedCompletionHandler completionHandler = ^(NSURLResponse * _Nonnull response,
                                                id _Nullable responseObject,
                                                NSError * _Nullable error) {
        if (error) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:feedPath]) {
                typeof(_images) backupImages = [NSKeyedUnarchiver unarchiveObjectWithFile:feedPath];
                [backupImages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull index,
                                                                 Fotka * _Nonnull backup,
                                                                 BOOL * _Nonnull stop) {
                    Fotka *fotka = [self fotkaForIndex:index];
                    @synchronized (fotka) {
                        fotka.src = backup.src;
                        fotka.author = backup.author;
                        fotka.filePath = backup.filePath;
                        if (fotka.required) {
                            [self downloadImage:fotka index:index.unsignedIntegerValue];
                        }
                    }
                }];
            }
        } else {
            GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithData:responseObject error:nil];
            NSArray *entries = [document.rootElement elementsForName:@"entry"];
            [entries enumerateObjectsUsingBlock:^(id _Nonnull entry, NSUInteger index, BOOL * _Nonnull stop) {
                GDataXMLElement *author = [entry elementsForName:@"author"][0];
                GDataXMLElement *name = [author elementsForName:@"name"][0];
                GDataXMLElement *uid = [author elementsForName:@"f:uid"][0];
                GDataXMLElement *content = [entry elementsForName:@"content"][0];
                NSString *src = [content attributeForName:@"src"].stringValue;
                Fotka *fotka = [self fotkaForIndex:[NSNumber numberWithUnsignedInteger:index]];
                @synchronized (fotka) {
                    fotka.src = src;
                    fotka.author = name.stringValue;
                    fotka.filePath = [self imageDestinationByAuthor:name.stringValue uid:uid.stringValue];
                    if (fotka.required) {
                        [self downloadImage:fotka index:index];
                    }
                }
            }];
            
            @synchronized (_images) {
                [NSKeyedArchiver archiveRootObject:_images toFile:feedPath];
            }
        }
        
        if (_downloadedFeedHandler) {
            _downloadedFeedHandler();
        }
    };
    
    [[_feedManager dataTaskWithRequest:request
                     completionHandler:completionHandler] resume];
}

- (void)downloadImage:(Fotka *)fotka index:(NSUInteger)index {
    if ([[NSFileManager defaultManager] fileExistsAtPath:fotka.filePath.path]) {
        if (_downloadedImageHandler) {
            _downloadedImageHandler(index);
        }
    } else {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:fotka.src]];

        Destination destination = ^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return fotka.filePath;
        };

        ImageCompletionHandler completionHandler = ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (!error) {
                if (_downloadedImageHandler) {
                    _downloadedImageHandler(index);
                }
            }
        };

        [[_imageManager downloadTaskWithRequest:request
                                       progress:nil
                                    destination:destination
                              completionHandler:completionHandler] resume];
    }
}

- (NSURL *)cachesDirectory {
    return [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                  inDomain:NSUserDomainMask
                                         appropriateForURL:nil
                                                    create:YES
                                                     error:nil];
}

- (NSURL *)feedDestination {
    return [[self cachesDirectory] URLByAppendingPathComponent:@"feed"];
}

- (NSURL *)imageDestinationByAuthor:(NSString *)author uid:(NSString *)uid {
    NSURL *path = [[self cachesDirectory] URLByAppendingPathComponent:author];

    [[NSFileManager defaultManager] createDirectoryAtURL:path
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];
    
    return [path URLByAppendingPathComponent:uid];
}

- (Fotka *)fotkaForIndex:(NSNumber *)index {
    Fotka *fotka;
    @synchronized (_images) {
        fotka = _images[index];
        if (fotka == nil) {
            fotka = [[Fotka alloc] init];
            _images[index] = fotka;
        }
    }
    
    return fotka;
}

- (void)cancelDownloads {
    _downloadedFeedHandler = nil;
    _downloadedImageHandler = nil;
    [_feedManager invalidateSessionCancelingTasks:YES];
    [_imageManager invalidateSessionCancelingTasks:YES];
}

@end
