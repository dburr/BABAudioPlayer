//
//  BABAudioPlaylist.m
//  Pods
//
//  Created by Bryn Bodayle on May/12/2015.
//
//

#import "BABAudioPlaylist.h"

@interface BABAudioPlaylist()

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation BABAudioPlaylist

+ (instancetype)audioPlaylistWithArray:(NSArray *)array {
    
    return [[self alloc] initWithArray:array];
}

- (instancetype)initWithArray:(NSArray *)array {
    
    self = [super init];
    if (self) {
        
        _array = [array mutableCopy];
    }
    return self;
}


- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    
    return _array[idx];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx {
    
    _array[idx] = obj;
}

- (NSInteger)count {
    
    return self.array.count;
}

@end
