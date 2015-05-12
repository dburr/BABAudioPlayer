//
//  BABAudioPlayer.h
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import <Foundation/Foundation.h>
#import "BABAudioPlayerDelegate.h"

#import "BABCurrentTimeScrubber.h"

typedef NS_ENUM(NSUInteger, BBAudioRouteChangedBehaviour) {
    BBAudioRouteChangedBehaviourContinuePlayback,
    BBAudioRouteChangedBehaviourPausePlayback,
    BBAudioRouteChangedBehaviourStopPlayback
};

typedef NS_ENUM(NSUInteger, BBAudioPlaybackInterruptionBehaviour) {
    BBAudioPlaybackInterruptionBehaviourShouldWait,
    BBAudioPlaybackInteruptionBehaviourShouldResume
};

typedef NS_ENUM(NSUInteger, BABAudioPlayerState) {
    BABAudioPlayerStateIdle,
    BABAudioPlayerStateBuffering,
    BABAudioPlayerStateWaiting,
    BABAudioPlayerStatePlaying,
    BABAudioPlayerStatePaused,
    BABAudioPlayerStateStopped,
    BABAudioPlayerStateScrubbing
};

@class BABAudioItem, UIEvent;

@interface BABAudioPlayer : NSObject

@property (nonatomic, readonly) BABAudioPlayerState state;

//now playing
@property (nonatomic, readonly) NSTimeInterval timeElapsed;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) float elapsedPercentage;
@property (nonatomic, readonly) BABAudioItem *currentAudioItem;
@property (nonatomic, readonly) NSArray *items;


//playback
@property (nonatomic, assign) float playbackRate; //defaults to 1.0
@property (nonatomic, assign) BOOL allowsMultitaskerControls; //defaults to YES
@property (nonatomic, assign) BOOL showsNowPlayingMetadata; //defaults to YES
@property (nonatomic, assign) BOOL allowsBackgroundAudio; //defaults to NO

@property (nonatomic, assign) BBAudioRouteChangedBehaviour audioRouteAddedBehaviour; //default value BBAudioRouteChangedBehaviourContinuePlayback
@property (nonatomic, assign) BBAudioRouteChangedBehaviour audioRouteRemovedBehaviour; //default value BBAudioRouteChangedBehaviourPausePlayback
@property (nonatomic, assign) BBAudioPlaybackInterruptionBehaviour audioPlaybackInterruptionBehaviour; //default value BBAudioPlaybackInterruptionBehaviourShouldWait

@property (nonatomic, weak) id <BABAudioPlayerDelegate> delegate;

+ (instancetype)sharedPlayer;
+ (void)setSharedPlayer:(BABAudioPlayer *)player;

- (void)queueItem:(BABAudioItem *)audioItem;
- (void)queueItems:(NSArray *)audioItems;
- (void)play;
- (void)togglePlaying;
- (void)stop;
- (void)pause;
- (void)next;
- (void)previous;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToPercent:(float)percent;
- (void)remoteControlReceivedWithEvent:(UIEvent *)event;

//UISlider Scrubbing
- (void)beginScrubbing:(id <BABCurrentTimeScrubber>)scrubber;
- (void)scrub:(id <BABCurrentTimeScrubber>)scrubber;
- (void)endScrubbing:(id <BABCurrentTimeScrubber>)scrubber;

@end