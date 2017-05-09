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

@property(nonatomic) AFURLSessionManager *feedManager;
@property(nonatomic) AFURLSessionManager *imageManager;
@property(nonatomic) void (^downloadedFeedHandler)();
@property(nonatomic) void (^downloadedImageHandler)(NSUInteger);
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

- (void)downloadFeed {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api-fotki.yandex.ru/api/podhistory/"]];
    
    FeedCompletionHandler completionHandler = ^(NSURLResponse * _Nonnull response, id _Nullable responseObject, NSError * _Nullable error) {
        if (!error) {
            GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithData:responseObject error:nil];
            if (document) {
                NSArray *entries = [document.rootElement elementsForName:@"entry"];
                [entries enumerateObjectsUsingBlock:^(id _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
                    int maxWidth = 0;
                    NSString *href = nil;
                    for (GDataXMLElement *img in [entry elementsForName:@"f:img"]) {
                        int width = [img attributeForName:@"width"].stringValue.intValue;
                        if (width > maxWidth) {
                            maxWidth = width;
                            href = [img attributeForName:@"href"].stringValue;
                        }
                    }
                    Fotka *fotka = [self fotkaForIndex:[NSNumber numberWithUnsignedInteger:idx]];
                    @synchronized (fotka) {
                        fotka.url = href;
                        if (fotka.required) {
                            [self downloadImage:fotka index:idx];
                        }
                    }
                }];
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
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:fotka.url]];
    
    Destination destination = ^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSURL *cachesDirectory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                                        inDomain:NSUserDomainMask
                                                               appropriateForURL:nil
                                                                          create:NO
                                                                           error:nil];
        
        return [cachesDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%lu", index]];
    };
    
    ImageCompletionHandler completionHandler = ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error) {
            @synchronized (fotka) {
                fotka.filePath = filePath;
            }
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
