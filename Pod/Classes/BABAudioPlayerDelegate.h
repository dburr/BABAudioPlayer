//
//  BBAudioPlayerDelegate.h
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BABAudioPlayerState);

@class BABAudioPlayer, BABAudioItem;

@protocol BABAudioPlayerDelegate <NSObject>

@optional
- (void)audioPlayer:(BABAudioPlayer *)player didChangeState:(BABAudioPlayerState)state;

- (void)audioPlayer:(BABAudioPlayer *)player didChangeElapsedTime:(NSTimeInterval)elapsedTime percentage:(float)percentage;

- (void)audioPlayer:(BABAudioPlayer *)player didBeginPlayingAudioItem:(BABAudioItem *)audioItem;
- (void)audioPlayer:(BABAudioPlayer *)player didFinishPlayingAudioItem:(BABAudioItem *)audioItem;
- (void)audioPlayer:(BABAudioPlayer *)player didLoadMetadata:(NSDictionary *)metadata forAudioItem:(BABAudioItem *)audioItem;
- (void)audioPlayer:(BABAudioPlayer *)player didFailPlaybackWithError:(NSError *)error;
@end
