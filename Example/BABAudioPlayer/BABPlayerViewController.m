//
//  BABPlayerViewController.m
//  BABAudioPlayer
//
//  Created by Bryn Bodayle on May/12/2015.
//  Copyright (c) 2015 Bryn Bodayle. All rights reserved.
//

#import "BABPlayerViewController.h"
#import "BABAudioPlayer.h"
#import "BABAudioUtilities.h"
#import "BABAudioItem.h"

@import MediaPlayer;

@interface BABPlayerViewController()<BABAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;
@property (weak, nonatomic) IBOutlet UILabel *timeElapsedLabel;
@property (weak, nonatomic) IBOutlet UIImageView *artworkImageView;
@property (weak, nonatomic) IBOutlet UILabel *songNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumNameLabel;

@property (nonatomic, strong) BABAudioPlayer *audioPlayer;


@end

@implementation BABPlayerViewController


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        _audioPlayer = [[BABAudioPlayer alloc] init];
        _audioPlayer.delegate = self;
        
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    BABConfigureSliderForAudioPlayer(self.sliderView, self.audioPlayer);
    
    [self loadAudioItem:self.audioItem];
}

- (void)loadAudioItem:(BABAudioItem *)audioItem {
    
    [self.audioPlayer queueItem:audioItem];
}

- (IBAction)playPauseButtonPressed:(UIButton *)sender {

    [self.audioPlayer togglePlaying];
}


#pragma - BABAudioPlayerDelegate

- (void)audioPlayer:(BABAudioPlayer *)player didBeginPlayingAudioItem:(BABAudioItem *)audioItem {
    
}

-(void)audioPlayer:(BABAudioPlayer *)player didFinishPlayingAudioItem:(BABAudioItem *)audioItem  {
    
    
}

- (void)audioPlayer:(BABAudioPlayer *)player didChangeState:(BABAudioPlayerState)state {
    
    switch (self.audioPlayer.state) {
        case BABAudioPlayerStatePlaying: {
            
            [self.activityIndicatorView stopAnimating];
            self.sliderView.enabled = YES;
            self.playPauseButton.hidden = NO;
            [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        }
            break;
        case BABAudioPlayerStateWaiting:
        case BABAudioPlayerStatePaused:
        {
            
            [self.activityIndicatorView stopAnimating];
            self.sliderView.enabled = state == BABAudioPlayerStatePaused;
            self.playPauseButton.hidden = NO;
            [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
        }
            break;
        case BABAudioPlayerStateBuffering: {
            
            self.sliderView.enabled = NO;
            self.playPauseButton.hidden = YES;
            [self.activityIndicatorView startAnimating];
        }
            break;
        case BABAudioPlayerStateScrubbing: {
            
            self.playPauseButton.hidden = YES;
        }
            break;
        case BABAudioPlayerStateStopped: {
            
            self.sliderView.hidden = YES;
            [self.activityIndicatorView stopAnimating];
            self.playPauseButton.hidden = YES;
            self.timeElapsedLabel.text = @"0:00/0:00";
        }
            break;
        default:
            break;
    }
}

- (void)audioPlayer:(BABAudioPlayer *)player didChangeElapsedTime:(NSTimeInterval)elapsedTime percentage:(float)percentage {
    
    self.sliderView.value = percentage;
    
    NSString *elapsedTimeString = BABFormattedTimeStringFromTimeInterval(elapsedTime);
    NSString *durationString = BABFormattedTimeStringFromTimeInterval(player.duration);
    
    self.timeElapsedLabel.text = [NSString stringWithFormat:@"%@/%@", elapsedTimeString, durationString];
    
}

- (void)audioPlayer:(BABAudioPlayer *)player didLoadMetadata:(NSDictionary *)metadata forAudioItem:(BABAudioItem *)audioItem {
    
    self.songNameLabel.text = metadata[MPMediaItemPropertyTitle];
    self.artistNameLabel.text = metadata[MPMediaItemPropertyArtist];
    self.albumNameLabel.text = metadata[MPMediaItemPropertyAlbumTitle];
    
    MPMediaItemArtwork *artwork = metadata[MPMediaItemPropertyArtwork];
    self.artworkImageView.image = [artwork imageWithSize:self.artworkImageView.frame.size];
    
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    
    [self.audioPlayer remoteControlReceivedWithEvent:event];
}


@end
