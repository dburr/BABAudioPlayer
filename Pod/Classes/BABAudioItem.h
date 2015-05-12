//
//  BABAudioItem.h
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import <Foundation/Foundation.h>

@interface BABAudioItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSURL *url;

@property (nonatomic, readonly) BOOL isRemoteStream;
@property (nonatomic, readonly) BOOL isLocalFile;

///---------------------------------------------
/// @name Creating and Initializing Audio Items
///---------------------------------------------

+ (instancetype)audioItemWithURL:(NSURL *)url;
- (instancetype)initWithURL:(NSURL *)url;

@end
