//
//  BABAudioPlaylist.h
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import <Foundation/Foundation.h>

@interface BABAudioPlaylist : NSObject

+ (instancetype)audioPlaylistWithArray:(NSArray *)array;
- (instancetype)initWithArray:(NSArray *)array;


- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;

@property (nonatomic, readonly) NSInteger count;

@end
