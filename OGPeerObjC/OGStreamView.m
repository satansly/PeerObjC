//
//  OGStreamView.m
//  Pods
//
//  Created by Omar Hussain on 2/13/16.
//
//

#import "OGStreamView.h"
#import "RTCMediaStream.h"
#import "RTCEAGLVideoView.h"
#import "RTCVideoTrack.h"
#import "RTCAudioTrack.h"
#import <AVFoundation/AVFoundation.h>
#import <EventEmitter/EventEmitter.h>

@interface OGStreamView ()<RTCEAGLVideoViewDelegate,RTCMediaStreamTrackDelegate>{
    
    CGSize _videoSize;
}


@property(nonatomic, strong) RTCEAGLVideoView* videoView;

@end
@implementation OGStreamView

-(instancetype)initWithStream:(RTCMediaStream *)stream {
    self = [super init];
    if(self) {
        _stream = stream;
        DDLogDebug(@"Initialized with Stream");
        [self resetSession];
    }
    return self;
}

-(void)setStream:(RTCMediaStream *)stream {
    NSAssert(stream != nil,@"Stream object provided to stream view is nil");
    _stream = stream;
    [self setupStream];
    
}

-(void)setupRendererViews {
    _videoView = [[RTCEAGLVideoView alloc] initWithFrame:self.bounds];
    _videoView.backgroundColor = [UIColor blackColor];
    _videoView.delegate = self;
    _videoView.transform = CGAffineTransformMakeScale(-1, 1);
    [self addSubview:_videoView];
    
    [self setupStream];
    
}

-(void)setupStream {
    if(_stream.videoTracks.count > 0) {
        RTCVideoTrack * videoTrack = _stream.videoTracks.firstObject;
        if(videoTrack)
            [videoTrack addRenderer:_videoView];
    }else{
        NSAssert(_stream.videoTracks.count > 0,@"Stream object has no video tracks");
        DDLogError(@"Stream object has no video tracks");
    }
}

-(void)resetRendererViews {
    [self removeRendererViews];
    [self setupRendererViews];
}
-(void)removeRendererViews {
    DDLogDebug(@"Removing renderers");
    for(RTCVideoTrack * track in _stream.videoTracks) {
        [track removeRenderer:_videoView];
    }
    [_videoView renderFrame:nil];
    DDLogDebug(@"Removing video view");
    if(_videoView) {
        [_videoView removeFromSuperview];
        _videoView = nil;
    }
}

#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size
{
    DDLogDebug(@"Video size changed.");
    if (videoView == _videoView) {
        _videoSize = size;
    } else {
        NSParameterAssert(NO);
    }
    [self updateVideoViewLayout];
    [self emit:@"size_change" data:[NSValue valueWithCGSize:size]];
    
}


- (void)mediaStreamTrackDidChange:(RTCMediaStreamTrack*)mediaStreamTrack {
    if(mediaStreamTrack.state == RTCTrackStateEnded || mediaStreamTrack.state == RTCTrackStateFailed) {
        DDLogDebug(@"Stream ended or failed. Resetting renderer view");
        [self resetRendererViews];
    }
    [self emit:@"state_change"];
}
- (void)resetSession
{
    DDLogDebug(@"Resetting streaming session");
    [self resetRendererViews];
    [self updateVideoViewLayout];
}

- (void)updateVideoViewLayout
{
    DDLogDebug(@"Trying to update video view frame, this may not work in views with autolayout");
    CGSize defaultAspectRatio = CGSizeMake(4, 3);
    CGSize aspectRatio = CGSizeEqualToSize(_videoSize, CGSizeZero) ? defaultAspectRatio : _videoSize;
    
    CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, self.bounds);
    _videoView.frame = videoFrame;
    
}


@end
