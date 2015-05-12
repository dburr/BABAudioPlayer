//
//  BABAudioUtilities.m
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import "BABAudioUtilities.h"
#import "BABAudioPlayer.h"

@import UIKit;

NSString *BABFormattedTimeStringFromTimeInterval(NSTimeInterval timeInterval) {
    
    NSString *timeString = nil;
    const int secsPerMin = 60;
    const int minsPerHour = 60;
    const char *timeSep = ":";
    NSTimeInterval seconds = timeInterval;
    seconds = floor(seconds);
    
    if(seconds < 60.0) {
        timeString = [NSString stringWithFormat:@"0:%02.0f", seconds];
    }
    else {
        int mins = seconds/secsPerMin;
        int secs = seconds - mins*secsPerMin;
        
        if(mins < 60.0) {
            timeString = [NSString stringWithFormat:@"%d%s%02d", mins, timeSep, secs];
        }
        else {
            int hours = mins/minsPerHour;
            mins -= hours * minsPerHour;
            timeString = [NSString stringWithFormat:@"%d%s%02d%s%02d", hours, timeSep, mins, timeSep, secs];
        }
    }
    return timeString;
}

UISlider <BABCurrentTimeScrubber> *BABCurrentTimeScrubberForAudioPlayer(BABAudioPlayer *audioPlayer) {
    
    UISlider *scrubber = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 236, 22)];
    
    return BABConfigureSliderForAudioPlayer(scrubber, audioPlayer);
}

UISlider <BABCurrentTimeScrubber> *BABConfigureSliderForAudioPlayer(UISlider *slider, BABAudioPlayer *audioPlayer) {
    
    for(id target in slider.allTargets) {
        
        [slider removeTarget:target action:NULL forControlEvents:UIControlEventAllEvents];
    }
    
    [slider addTarget:audioPlayer action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [slider addTarget:audioPlayer action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchCancel];
    [slider addTarget:audioPlayer action:@selector(scrub:) forControlEvents:UIControlEventTouchDragInside];
    [slider addTarget:audioPlayer action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:audioPlayer action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [slider addTarget:audioPlayer action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    slider.continuous = YES;
    
    UISlider<BABCurrentTimeScrubber> *currentTimeScrubber = (UISlider<BABCurrentTimeScrubber> *)slider;
    return currentTimeScrubber;
}