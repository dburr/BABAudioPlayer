//
//  BABCurrentTimeScrubber.h
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import <Foundation/Foundation.h>

@protocol BABCurrentTimeScrubber <NSObject>

- (float)value;
- (float)maximumValue;
- (float)minimumValue;

@end
