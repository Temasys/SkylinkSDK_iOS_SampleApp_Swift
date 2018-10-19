//
//  AVAudioSession+Swift.m
//  SampleApp
//
//  Created by Yuxi Liu on 19/10/18.
//  Copyright © 2018 Yuxi. All rights reserved.
//

#import "AVAudioSession+Swift.h"

@implementation AVAudioSession (Swift)
- (BOOL)swift_setCategory:(AVAudioSessionCategory)category error:(NSError **)outError {
    return [self setCategory:category error:outError];
}
@end
