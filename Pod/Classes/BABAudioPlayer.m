//
//  BABAudioPlayer.m
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import "BABAudioPlayer.h"
#import "BABAudioItem.h"
#import <UIKit/UIEvent.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

static BABAudioPlayer  *sharedPlayer = nil;

@interface BABAudioPlayer() {
    
    float previousPlaybackRate;
    NSInteger currentIndex;
}

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) id playbackObserver;
@property (nonatomic, strong) dispatch_queue_t playbackQueue;
@property (nonatomic, assign) BOOL newMediaItem;
@property (nonatomic, readwrite) BABAudioItem *currentAudioItem;

@property (nonatomic, readwrite) BABAudioPlayerState state;

@end

@implementation BABAudioPlayer

+ (instancetype)sharedPlayer {
    
    return sharedPlayer;
}
+ (void)setSharedPlayer:(BABAudioPlayer *)player {
    
    sharedPlayer = player;
}

+ (BABAudioPlayer *)sharedInstance {
    
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (void)dealloc {
    
    [self stop];
}

- (id)init {
    self = [super init];
    if (self) {
        
        self.state = BABAudioPlayerStateIdle;
        self.playbackRate = 1.0;
        self.allowsMultitaskerControls = YES;
        self.showsNowPlayingMetadata = YES;
        self.allowsBackgroundAudio = NO;
        self.audioRouteAddedBehaviour = BBAudioRouteChangedBehaviourContinuePlayback;
        self.audioRouteRemovedBehaviour = BBAudioRouteChangedBehaviourPausePlayback;
        self.audioPlaybackInterruptionBehaviour = BBAudioPlaybackInterruptionBehaviourShouldWait;
        
        _playbackQueue = dispatch_queue_create("com.BABAudioPlayer.playbackqueue", NULL);
        
    }
    return self;
}

#pragma - State

- (void)setState:(BABAudioPlayerState)state {
    
    BOOL stateChanged = state != _state;
    
    _state = state;
    
    if(stateChanged) {
        
        if([self.delegate respondsToSelector:@selector(audioPlayer:didChangeState:)]) {
            
            [self.delegate audioPlayer:self didChangeState:state];
        }
    }
}

- (float)elapsedPercentage {
    
    NSTimeInterval timeElapsed = CMTimeGetSeconds(self.player.currentTime);
    return timeElapsed/self.duration;
}

- (NSTimeInterval)timeElapsed {
    
    return CMTimeGetSeconds(self.player.currentTime);
}

- (NSTimeInterval)duration {
    
    return CMTimeGetSeconds(self.player.currentItem.duration);
}

- (void)setAllowsBackgroundAudio:(BOOL)allowsBackgroundAudio {
    
    if(allowsBackgroundAudio){
        
        NSDictionary *plistDict = [[NSBundle mainBundle] infoDictionary];
        NSArray *backgroundModes = plistDict[@"UIBackgroundModes"];
        
        NSAssert([backgroundModes containsObject:@"audio"], @"The required background mode for audio should be included in your Info.plist");
    }
    
    _allowsBackgroundAudio = allowsBackgroundAudio;
}

#pragma - Notifications

- (void)audioRouteChanged:(NSNotification *)notification {
    
    AVAudioSessionRouteChangeReason reason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
    
    switch (reason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable: {
            
            switch ([BABAudioPlayer sharedInstance].audioRouteAddedBehaviour) {
                case BBAudioRouteChangedBehaviourContinuePlayback:
                    break;
                case BBAudioRouteChangedBehaviourPausePlayback:
                    [[BABAudioPlayer sharedInstance] pause];
                    break;
                case BBAudioRouteChangedBehaviourStopPlayback:
                    [[BABAudioPlayer sharedInstance] stop];
                    break;
                default:
                    break;
            }
        }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            
            switch ([BABAudioPlayer sharedInstance].audioRouteRemovedBehaviour) {
                case BBAudioRouteChangedBehaviourContinuePlayback:
                    break;
                case BBAudioRouteChangedBehaviourPausePlayback:
                    [[BABAudioPlayer sharedInstance] pause];
                    break;
                case BBAudioRouteChangedBehaviourStopPlayback:
                    [[BABAudioPlayer sharedInstance] stop];
                    break;
                default:
                    break;
            }
        }
            break;
        default:
            break;
    }
}

- (void)audioInterruption:(NSNotification *)notification {
    
    AVAudioSessionInterruptionType interruptionType = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    AVAudioSessionInterruptionOptions interruptionOptions = [notification.userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
    
    NSLog(@"hey");
}

- (void)playbackDidPlayToEndTime:(NSNotification *)notification {
    
    [self stop];
}

#pragma - Actions

- (void)queueItem:(BABAudioItem *)audioItem {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(self.player) {
        [self stop];
    }
    
    dispatch_async(_playbackQueue, ^{
        
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:audioItem.url];
        self.player = [[AVPlayer alloc] initWithPlayerItem:item];
        self.newMediaItem = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [self.player.currentItem addObserver:self forKeyPath:NSStringFromSelector(@selector(status)) options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:NULL];
        [self.player addObserver:self forKeyPath:NSStringFromSelector(@selector(rate)) options:NSKeyValueObservingOptionNew context:NULL];
        
        _currentAudioItem = audioItem;
        
        if(self.showsNowPlayingMetadata){
            [self updateNowPlayingMetadata:audioItem];
        }
        
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInterruption:) name:AVAudioSessionInterruptionNotification object:nil];

    });
    
}

- (void)queueItems:(NSArray *)audioItems {
    
    NSAssert(audioItems, @"The array can not be nil.");
    
    _items = audioItems;
    
    [self queueItem:audioItems[0]];
    currentIndex = 0;
}

- (void)play {
    
    dispatch_async(_playbackQueue, ^{
        
        [self.player play];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if(!self.playbackObserver)
                [self startTimeObserver];
            
            if(self.allowsBackgroundAudio) {
                
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            }
            
            if(self.allowsMultitaskerControls)
                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            
        });
        
    });
    
    
    
}
- (void)togglePlaying {
    
    if (self.state == BABAudioPlayerStatePlaying)
        [self pause];
    else if(self.state == BABAudioPlayerStateWaiting || self.state == BABAudioPlayerStatePaused) {
        
        [self play];
    }
}
- (void)stop {
    
    self.state = BABAudioPlayerStateStopped;
    
    [self.player.currentItem removeObserver:self forKeyPath:NSStringFromSelector(@selector(status))];
    [self.player removeObserver:self forKeyPath:NSStringFromSelector(@selector(rate))];
    [self.player removeTimeObserver:self.playbackObserver];
    self.player.rate = 0;
    
    self.player = nil;
    self.playbackObserver = nil;
    
    if([self.delegate respondsToSelector:@selector(audioPlayer:didFinishPlayingAudioItem:)])
        [self.delegate audioPlayer:self didFinishPlayingAudioItem:self.currentAudioItem];
    
    self.currentAudioItem = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    
    if(self.allowsMultitaskerControls) {
     
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    }
}
- (void)pause {
    
    [self.player pause];
}

- (void)next {
    
    currentIndex++;
    [self queueItem:_items[currentIndex]];
}

- (void)previous {
    
    if(self.duration > 30) {
        
        [self seekToTime:0];
    }
    else {
        
        currentIndex--;
        [self queueItem:_items[currentIndex]];
    }
}



- (void)seekToTime:(NSTimeInterval)time {
    
    [self.player seekToTime:CMTimeMakeWithSeconds(time, 1)];
}

- (void)seekToPercent:(float)percent {
    
    NSTimeInterval timeInterval = self.duration * percent;
    
    [self seekToTime:timeInterval];
}

#pragma - Internal

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if(self.state != BABAudioPlayerStateScrubbing && [keyPath isEqualToString:NSStringFromSelector(@selector(rate))]) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if(self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                
                float newRate = [change[NSKeyValueChangeNewKey] floatValue];
                float oldRate = [change[NSKeyValueChangeOldKey] floatValue];
                
                if(newRate == 1 && newRate != oldRate) {
                    self.state = BABAudioPlayerStatePlaying;
                }
                else {
                    self.state = BABAudioPlayerStatePaused;
                }
            }
        }];
    }
    else if([keyPath isEqualToString:NSStringFromSelector(@selector(status))]) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            switch (self.player.currentItem.status) {
                case AVPlayerItemStatusUnknown:
                    
                    self.state = BABAudioPlayerStateBuffering;
                    break;
                case AVPlayerItemStatusReadyToPlay: {
                    
                    self.state = BABAudioPlayerStateWaiting;
                }
                    break;
                case AVPlayerItemStatusFailed: {
                    
                    NSLog(@"%@", self.player.error.localizedDescription);
                    self.state = BABAudioPlayerStateStopped;
                    
                    if([self.delegate respondsToSelector:@selector(audioPlayer:didFailPlaybackWithError:)]) {
                        
                        [self.delegate audioPlayer:self didFailPlaybackWithError:self.player.error];
                    }
                }
                    break;
                default:
                    break;
            }
        }];
    }
}

#pragma - Metadata

- (void)updateNowPlayingMetadata:(BABAudioItem *)audioItem {
    
    __block AVAsset *asset = self.player.currentItem.asset;
    
    __weak typeof(self)weakSelf = self;
    
    [self.player.currentItem.asset loadValuesAsynchronouslyForKeys:@[@"commonMetadata"] completionHandler:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
            
            NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionaryWithCapacity:5];
            
            AVMetadataItem *title = [weakSelf localizedMetadataItemFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyTitle];
            
            if(title) {
                nowPlayingInfo[MPMediaItemPropertyTitle] = title.stringValue;
            }
            
            AVMetadataItem *artist = [weakSelf localizedMetadataItemFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyArtist];
            
            if(artist) {
                nowPlayingInfo[MPMediaItemPropertyArtist] = artist.stringValue;
            }
            
            AVMetadataItem *albumName = [weakSelf localizedMetadataItemFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyAlbumName];
            
            if(albumName) {
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumName.stringValue;
            }
            
            AVMetadataItem *artwork = [weakSelf localizedMetadataItemFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyArtwork];
            
            if(artwork) {
                
                NSData *data = nil;

                if([artwork.value isKindOfClass:[NSData class]]) {
                    
                    data = (NSData *)artwork.value;
                }
                
                if(data) {
                    
                    UIImage *image = [UIImage imageWithData:data];
                    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork;
                }
            }
            
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(CMTimeGetSeconds(asset.duration));
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
                
                if([weakSelf.delegate respondsToSelector:@selector(audioPlayer:didLoadMetadata:forAudioItem:)]) {
                    
                    [weakSelf.delegate audioPlayer:weakSelf didLoadMetadata:nowPlayingInfo forAudioItem:audioItem];
                }
            });
        });
    }];
}

- (AVMetadataItem *)localizedMetadataItemFromArray:(NSArray *)array withKey:(id)key {
    
    AVMetadataItem *metadataItem = nil;
    
    NSArray *metadataItems = [AVMetadataItem metadataItemsFromArray:array withKey:key keySpace:AVMetadataKeySpaceCommon];
    
    if (metadataItems.count > 0) {
        
        NSArray *preferredLanguages = [NSLocale preferredLanguages];
        
        for (NSString *thisLanguage in preferredLanguages) {
            
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:thisLanguage];
            NSArray *metadataForLocale = [AVMetadataItem metadataItemsFromArray:metadataItems withLocale:locale];
            
            if (metadataForLocale.count > 0) {
                
                metadataItem = metadataForLocale[0];
                break;
            }
        }
        
        if (!metadataItem) {
            
            metadataItem = metadataItems[0];
        }
    }
    
    return metadataItem;
}

#pragma - Playback Observation

- (void)startTimeObserver {
    
    __block BABAudioPlayer *blockSelf = self;
    
    self.playbackObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1)  queue:NULL usingBlock:^(CMTime time){
        
        [blockSelf timeElapsedChanged];
    }];
}

- (void)stopTimeObserver {
    
    [self.player removeTimeObserver:self.playbackObserver];
    self.playbackObserver = nil;
}

- (void)timeElapsedChanged {
    
    NSTimeInterval timeElapsed = CMTimeGetSeconds(self.player.currentTime);
    
    float percentage = timeElapsed/self.duration;
    
    if([self.delegate respondsToSelector:@selector(audioPlayer:didChangeElapsedTime:percentage:)]) {
        [self.delegate audioPlayer:self didChangeElapsedTime:timeElapsed percentage:percentage];
    }
    
    if(self.showsNowPlayingMetadata) {
        
        NSMutableDictionary *nowPlayingInfo = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.timeElapsed);
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = @(self.playbackRate);
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
    }
    
}

#pragma  - Multitasker Controls

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    
    if(self.allowsMultitaskerControls) {
        
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self togglePlaying];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [self play];
                break;
            case UIEventSubtypeRemoteControlPause:
                [self pause];
                break;
            case UIEventSubtypeRemoteControlStop:
                [self stop];
            case UIEventSubtypeRemoteControlNextTrack:
                [self next];
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self previous];
            default:
                break;
        }
    }
}

#pragma - UISlider Scrubbing

- (void)beginScrubbing:(id <BABCurrentTimeScrubber>)scrubber {
    
    self.state = BABAudioPlayerStateScrubbing;
    previousPlaybackRate = self.player.rate;
    self.player.rate = 0;
}

- (void)scrub:(id <BABCurrentTimeScrubber>)scrubber {
    
    CMTime playerDuration = self.player.currentItem.duration;
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        
        float minValue = scrubber.minimumValue;
        float maxValue = scrubber.maximumValue;
        float value = scrubber.value;
        
        double time = duration * (value - minValue) / (maxValue - minValue);
        
        [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    }
}

- (void)endScrubbing:(id <BABCurrentTimeScrubber>)scrubber {
    
    if (!self.playbackObserver) {
        CMTime playerDuration = self.player.currentItem.duration;
        
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            
            [self startTimeObserver];
        }
    }
    self.player.rate = previousPlaybackRate;
    self.state = self.player.rate == 1.0f ? BABAudioPlayerStatePlaying : BABAudioPlayerStatePaused;
}



@end
