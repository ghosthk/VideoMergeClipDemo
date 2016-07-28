//
//  ZPVideoPlaybackView.h
//  VideoMergeClipDemo
//
//  Created by Ghost on 28/7/2016.
//  Copyright © 2016 ghost. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ZPVideoPlaybackView : UIView

@property (nonatomic, weak) AVPlayer *player;

- (AVPlayerLayer *)playerLayer;

@end
