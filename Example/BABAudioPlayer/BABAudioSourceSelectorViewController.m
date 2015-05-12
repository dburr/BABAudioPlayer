//
//  BABAudioSourceSelectorViewController.m
//  BABAudioPlayer
//
//  Created by Bryn Bodayle on May/12/2015.
//  Copyright (c) 2015 Bryn Bodayle. All rights reserved.
//

#import "BABAudioSourceSelectorViewController.h"
#import "BABAudioItem.h"
#import "BABPlayerViewController.h"

@implementation BABAudioSourceSelectorViewController

- (IBAction)iPodLibraryButtonPressed:(UIButton *)sender {
    
    
}

- (IBAction)localFileButtonPressed:(UIButton *)sender {
    
    
}

- (IBAction)remoteFileButtonPressed:(UIButton *)sender {
    
    NSURL *URL = [NSURL URLWithString:@"http://brynbodayle.com/Files/18%20Down%20To%20The%20Sound.mp3"];
    BABAudioItem *remoteFileAudioItem = [BABAudioItem audioItemWithURL:URL];
    
    BABPlayerViewController *playerViewController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([BABPlayerViewController class])];
    playerViewController.audioItem = remoteFileAudioItem;
    [self.navigationController pushViewController:playerViewController animated:YES];
}


@end
