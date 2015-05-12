//
//  BABAudioUtilities.h
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import <Foundation/Foundation.h>
#import "BABCurrentTimeScrubber.h"

@class BABAudioPlayer, UISlider;

NSString *BABFormattedTimeStringFromTimeInterval(NSTimeInterval timeInterval);
UISlider <BABCurrentTimeScrubber> *BABCurrentTimeScrubberForAudioPlayer(BABAudioPlayer *audioPlayer);
UISlider <BABCurrentTimeScrubber> *BABConfigureSliderForAudioPlayer(UISlider *slider, BABAudioPlayer *audioPlayer);
