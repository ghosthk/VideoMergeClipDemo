//
//  ViewController.m
//  VideoMergeClipDemo
//
//  Created by Ghost on 28/7/2016.
//  Copyright © 2016 ghost. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "ZPVideoPlaybackView.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIButton  *buttonMerge;
@property (nonatomic, weak) IBOutlet UIButton  *buttonClip;

@property (nonatomic, weak) IBOutlet ZPVideoPlaybackView *mergeVideoView;
@property (nonatomic, weak) IBOutlet ZPVideoPlaybackView *clipVideoView;

@property (nonatomic, strong) AVPlayer  *mergePlayer;
@property (nonatomic, strong) AVPlayer  *clipPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.clipPlayer = [AVPlayer new];
    self.clipVideoView.player = _clipPlayer;
    
    self.mergePlayer = [AVPlayer new];
    self.mergeVideoView.player = _mergePlayer;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)mergeClick:(id)sender {
    [_buttonMerge setEnabled:NO];
    [self merge];
}

- (IBAction)clipClick:(id)sender {
    [_buttonClip setEnabled:NO];
    [self clip];
}

- (void)merge {
    [_mergePlayer pause];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[self mergeUrl] path]]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:[self mergeUrl] error:&error];
        NSLog(@"remove exist file %@",error);
    }
    
    NSString *aPath = [[NSBundle mainBundle] pathForResource:@"A" ofType:@"mp4"];
    NSString *bPath = [[NSBundle mainBundle] pathForResource:@"B" ofType:@"mp4"];
    
    NSArray *videoPaths = @[aPath,bPath];
    
    AVMutableComposition *mainComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *compositionVideoTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *soundtrackTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime duration = kCMTimeZero;
    for(NSString *videoPath in videoPaths){
        AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:duration error:nil];
        
        [soundtrackTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:duration error:nil];
        
        duration = CMTimeAdd(duration, asset.duration);
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mainComposition presetName:AVAssetExportPreset1280x720];
    
    exporter.outputURL = [self mergeUrl];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    __weak typeof(self) weakSelf = self;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch (exporter.status) {
            case AVAssetExportSessionStatusWaiting:
                break;
            case AVAssetExportSessionStatusExporting:
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporting completed");
                // 想做什么事情在这个做
                [weakSelf _mergeFinished];
                break;
            default:
                [weakSelf _mergeFinished];
                NSLog(@"exporting failed %@",[exporter error]);
                break;
        }
        
    }];
}

- (CGFloat)_videoSecondes:(AVAsset*)asset {
    return asset.duration.value*1.0f/asset.duration.timescale;
}

- (void)clip {
    [_clipPlayer pause];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[self clipUrl] path]]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:[self clipUrl] error:&error];
        NSLog(@"remove exist file %@",error);
    }
    
    NSString *clipPath = [[self mergeUrl] path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:clipPath]) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Your clip file is not found. please click merge. then click clip." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        [_buttonClip setEnabled:YES];
        return;
    }
    
    AVMutableComposition *mainComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *compositionVideoTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *soundtrackTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime duration = kCMTimeZero;
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:clipPath]];
    float videoSecondes = [self _videoSecondes:asset];
    
    CMTimeRange rangeTime = CMTimeRangeMake(CMTimeMakeWithSeconds( videoSecondes*0.3f, asset.duration.timescale), CMTimeMakeWithSeconds( videoSecondes*0.5f, asset.duration.timescale));
    [compositionVideoTrack insertTimeRange:rangeTime ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:duration error:nil];
    
    [soundtrackTrack insertTimeRange:rangeTime ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:duration error:nil];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mainComposition presetName:AVAssetExportPreset1280x720];
    
    exporter.outputURL = [self clipUrl];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    __weak typeof(self) weakSelf = self;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch (exporter.status) {
            case AVAssetExportSessionStatusWaiting:
                break;
            case AVAssetExportSessionStatusExporting:
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporting completed");
                // 想做什么事情在这个做
                [weakSelf _clipFinished];
                break;
            default:
                [weakSelf _clipFinished];
                NSLog(@"exporting failed %@",[exporter error]);
                break;
        }
        
    }];
}

- (NSString *)_localCachePath
{
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                               NSUserDomainMask, YES) firstObject];
    return cachePath;
}

- (NSURL*)mergeUrl {
    NSArray *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [docPath objectAtIndex:0];
    return [NSURL fileURLWithPath:[documentsPath stringByAppendingPathComponent:@"merge.mp4"]];
}

- (NSURL*)clipUrl {
    NSArray *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [docPath objectAtIndex:0];
    return [NSURL fileURLWithPath:[documentsPath stringByAppendingPathComponent:@"clip.mp4"]];
}


- (void)_mergeFinished {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_buttonMerge setEnabled:YES];
        [self _playMergeVideo];
    });
}

- (void)_clipFinished {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_buttonClip setEnabled:YES];
        [self _playClipVideo];
    });
}

- (void)_playMergeVideo {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[self mergeUrl] options:nil];
    [_mergePlayer replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
    [_mergePlayer play];
}

- (void)_playClipVideo {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[self clipUrl] options:nil];
    [_clipPlayer replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
    [_clipPlayer play];
}

@end
