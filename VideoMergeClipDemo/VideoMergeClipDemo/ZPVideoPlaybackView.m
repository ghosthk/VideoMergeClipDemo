//
//  ZPVideoPlaybackView.m
//  VideoMergeClipDemo
//
//  Created by Ghost on 28/7/2016.
//  Copyright © 2016 ghost. All rights reserved.
//

#import "ZPVideoPlaybackView.h"

@implementation ZPVideoPlaybackView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor blackColor];
}

- (AVPlayer *)player {
    return [[self playerLayer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [[self playerLayer] setVideoGravity:AVLayerVideoGravityResizeAspect];
    [[self playerLayer] setPlayer:player];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self layer];
}

@end

