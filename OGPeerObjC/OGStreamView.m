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
    [self removeRendererViews];
    [self setupRendererViews];
    
}

-(void)setupRendererViews {
        DDLogDebug(@"Setting up renderers");
    _videoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.height * (9.0/16.0), self.bounds.size.height)];
    _videoView.backgroundColor = [UIColor clearColor];
    _videoView.delegate = self;
    _videoView.contentMode = UIViewContentModeScaleAspectFill;
    _videoView.transform = CGAffineTransformMakeScale(-1, 1);
    [self addSubview:_videoView];
    
    [self setupStream];
    
}

-(void)setupStream {
    if(_stream.videoTracks.count > 0) {
        RTCVideoTrack * videoTrack = _stream.videoTracks.firstObject;
        videoTrack.delegate = self;
        if(videoTrack)
            [videoTrack addRenderer:_videoView];
    }else{
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
        [track setDelegate:nil];
    }
    [_videoView renderFrame:nil];
    DDLogDebug(@"Removing video view");
    if(_videoView) {
        _videoView.delegate = nil;
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
        //NSParameterAssert(NO);
    }
    [self updateVideoViewLayout];
    [self emit:@"size_change" data:[NSValue valueWithCGSize:size]];
    
}


- (void)mediaStreamTrackDidChange:(RTCMediaStreamTrack*)mediaStreamTrack {
    if(mediaStreamTrack.state == RTCTrackStateEnded || mediaStreamTrack.state == RTCTrackStateFailed) {
        DDLogDebug(@"Stream ended or failed. Resetting renderer view");

        dispatch_async(dispatch_get_main_queue(),^{
            [self resetRendererViews];
        });
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
    CGSize defaultAspectRatio = CGSizeMake(9, 16);
    CGSize aspectRatio = CGSizeEqualToSize(_videoSize, CGSizeZero) ? defaultAspectRatio : _videoSize;
    CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, CGRectMake(0, 0, self.bounds.size.height * aspectRatio.width/aspectRatio.height , self.bounds.size.height));
    _videoView.frame = videoFrame;
    
}
- (void)dealloc{
    [self removeRendererViews];
    _stream = nil;
}


@end
