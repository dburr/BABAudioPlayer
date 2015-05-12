//
//  BABAudioItem.m
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import "BABAudioItem.h"

@interface BABAudioItem()

@property (nonatomic, strong) NSString *urlString;

@end

@implementation BABAudioItem

+ (instancetype)audioItemWithURL:(NSURL *)url {
    
    return [[self alloc] initWithURL:url];
}
- (instancetype)initWithURL:(NSURL *)url {
    
    self = [super init];
    if (self) {
        
        _url = url;
        _urlString = url.absoluteString;
    }
    return self;
    
}


@end
