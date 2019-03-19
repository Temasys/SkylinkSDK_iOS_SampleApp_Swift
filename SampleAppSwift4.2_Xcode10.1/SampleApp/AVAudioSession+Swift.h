//
//  AVAudioSession+Swift.h
//  SampleApp
//
//  Created by Yuxi Liu on 19/10/18.
//  Copyright © 2018 Yuxi. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioSession (Swift)
- (BOOL)swift_setCategory:(AVAudioSessionCategory)category error:(NSError **)outError NS_SWIFT_NAME(setCategory(_:));
@end

NS_ASSUME_NONNULL_END
