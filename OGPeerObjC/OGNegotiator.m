//
//  OGNegotiator.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGNegotiator.h"
#import "RTCDataChannel.h"
#import "RTCPair.h"
#import "RTCMediaConstraints.h"
#import "RTCPeerConnectionFactory.h"
#import "OGUtil.h"
#import "OGPeer.h"
#import "OGMessage.h"
#import "OGDataConnection.h"
#import "OGMediaConnection.h"
#import "OGPeerConnectionDelegate.h"
#import "OGSessionDescriptionDelegate.h"
#import "RTCICECandidate.h"
#import "RTCVideoCapturer.h"
#import <AVFoundation/AVFoundation.h>



@interface OGNegotiatorOptions ()
@end
@implementation OGNegotiatorOptions
@end

@interface OGNegotiator ()
@property (nonatomic, strong) RTCPeerConnectionFactory * factory;
@property (nonatomic, strong) OGPeer * provider;
@property (nonatomic, strong) NSMutableDictionary * pcs;
@property (nonatomic, strong)  OGSessionDescriptionDelegate * sdpDelegate;
@property (nonatomic, strong)  OGPeerConnectionDelegate * pcDelegate;
@end
@implementation OGNegotiator
-(instancetype)initWithOptions:(OGNegotiatorOptions *)options {
    self = [super init];
    if(self) {
        _options = options;
        _factory = [[RTCPeerConnectionFactory alloc] init];
        _pcs = [NSMutableDictionary dictionary];
    }
    return self;
    
}
-(RTCPeerConnection *)startConnection:(OGConnection *)connection options:(OGNegotiatorOptions *)options {
    DDLogDebug(@"Attempting to start connection with peer %@ of type %@",connection.peer,connection.typeAsString );
    _options = options;
    RTCPeerConnection * pc = [self getPeerConnection:connection options:options];
    if(pc) {
        connection.peerConnection = pc;
    }
    if (connection.type == OGConnectionTypeMedia) {
        
        // Add the stream.
        OGMediaConnection * conn  = (OGMediaConnection *)connection;
        OGMediaConnectionOptions * options = conn.options;
        if(options.type == OGStreamTypeVideo || options.type == OGStreamTypeBoth) {
            DDLogDebug(@"Creating and adding video stream for connection %@",connection.identifier);
            RTCMediaStream * stream = [self addLocalVideoStream:options.direction];
            if(stream) {
                conn.localVideoStream = stream;
                [pc addStream: conn.localVideoStream];
            }else
                DDLogWarn(@"Video stream was not created for connection %@",connection.identifier);
        }
        if(options.type == OGStreamTypeAudio || options.type == OGStreamTypeBoth) {
            DDLogDebug(@"Creating and adding audio stream");
            RTCMediaStream * stream =  [self addLocalAudioStream];
            if(stream) {
                conn.localAudioStream = stream;
                [pc addStream:conn.localAudioStream];
            }else
                DDLogWarn(@"Audio stream was not created for connection %@",connection.identifier);
            
        }
    }
    if (options.originator) {
        if (connection.type == OGConnectionTypeData) {
            DDLogDebug(@"Creating data channel %@ with peer %@",connection.label,connection.peer);
            // Create the datachannel.
            RTCDataChannelInit * config = [[RTCDataChannelInit alloc] init];
            RTCDataChannel * dc = [pc createDataChannelWithLabel:connection.label config:config];
            [((OGDataConnection *)connection) initialize:dc];
        }
        
        
    }
    if (options.originator) {
        [self makeOffer:connection];
    } else {
        [self handleSDP:OGMessageTypeOffer connection:connection sdp:options.payload.sdp];
    }
    return pc;
}
-(RTCPeerConnection *)getPeerConnection:(OGConnection *)connection options:(OGNegotiatorOptions *)options {
    DDLogDebug(@"Retrieving peer connection with peer %@ of type %@",connection.peer, connection.typeAsString);
    if (!self.pcs[connection.typeAsString]) {
        DDLogError(@"%@ is not a valid connection type. Maybe you overrode the `type` property somewhere.",connection.typeAsString);
    }
    
    
    
    RTCPeerConnection * pc = ((NSDictionary *)self.pcs[connection.typeAsString])[connection.peer];
    
    if (!pc || pc.signalingState != RTCSignalingStable) {
        DDLogDebug(@"A peer connection or a stable peer connection was not found. ");
        pc = [self startPeerConnection:connection];
    }
    return pc;
}
- (RTCPeerConnection *)startPeerConnection:(OGConnection *)connection {
    
    DDLogDebug(@"Attempting to create new peer connection with peer %@ or type %@",connection.peer, connection.typeAsString);
    NSArray *optionalConstraints = nil;
    
    
    
    if (connection.type == OGConnectionTypeData) {
        optionalConstraints = @[]
        ;
    } else if (connection.type == OGConnectionTypeMedia) {
        // Interop req for chrome.
        optionalConstraints = @[
                                [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                ];
    }
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
    
    _pcDelegate = [[OGPeerConnectionDelegate alloc] initWithConnection:connection negotiator:self];
    
    
    RTCPeerConnection * pc =  [_factory peerConnectionWithICEServers:connection.provider.options.config.iceServers constraints:constraints delegate:_pcDelegate];
    NSMutableDictionary * connPCs = self.pcs[connection.typeAsString];
    if(!connPCs) {
        connPCs = [NSMutableDictionary dictionary];
    }
    connPCs[connection.peer] = pc;
    self.pcs[connection.typeAsString] = connPCs;
    
    
    
    return pc;
}
/** Handle an SDP. */
- (void)handleSDP:(OGMessageType)type connection:(OGConnection *)connection sdp:(RTCSessionDescription *)sdp {
    DDLogDebug(@"Handling session description received from peer %@  with message type %@ for connection %@",connection.peer,[[OGUtil util] stringFromMessageType:type],connection.typeAsString);
    
    __weak typeof (self) weakSelf = self;
    RTCPeerConnection * pc = connection.peerConnection;
    _sdpDelegate = [[OGSessionDescriptionDelegate alloc] initWithConnection:connection negotiator:self];
    
    
    _sdpDelegate.didSetSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        if(!error) {
            if (type == OGMessageTypeOffer) {
                [weakSelf makeAnswer:connection];
            }
        }else{
            //TODO:webrtc error
            [connection emit:@"error" data:[NSError errorWithLocalizedDescription:error.localizedDescription]];
            DDLogError(@"Failed to set remote description: %@",error.localizedDescription);
        }
    };
    DDLogDebug(@"Setting remote description");
    [pc setRemoteDescriptionWithDelegate:_sdpDelegate sessionDescription:sdp];
    
}




/** Handle a candidate. */
- (void)handleCandidate:(OGConnection *)connection ice:(RTCICECandidate *)candidate {
    [connection.peerConnection addICECandidate:candidate];
    DDLogDebug(@"Added ICE candidate for: %@",connection.peer);
}

-(void)cleanup:(OGConnection *)connection {
    DDLogDebug(@"'Cleaning up PeerConnection to %@", connection.peer);
    OGMessage * leave = [OGMessage leaveWithConnection:connection];
    [connection.provider send:leave connection:connection.identifier];
    RTCPeerConnection * pc = connection.peerConnection;
    
    if (pc && pc.signalingState != RTCSignalingClosed) {
        [pc close];
    }
    connection.peerConnection = nil;
}

- (void)makeOffer:(OGConnection *)connection {
    RTCPeerConnection * pc = connection.peerConnection;
    _sdpDelegate = [[OGSessionDescriptionDelegate alloc] initWithConnection:connection negotiator:self];
    _sdpDelegate.didCreateSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        if(!error) {
            
            
        }else{
            //TODO: webrtc error
            [connection emit:@"error" data:[NSError errorWithLocalizedDescription:error.localizedDescription]];
            DDLogError(@"Failed to createOffer: %@",error.localizedDescription);
        }
    };
    _sdpDelegate.didSetSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        if(!error) {
            OGMessage * offer = [OGMessage offerWithConnection:connection];
            [connection.provider send:offer connection:connection.identifier];
            
        }else{
            
            [connection emit:@"error" data:[NSError errorWithLocalizedDescription:error.localizedDescription]];
            DDLogError(@"Failed to set local description: %@",error.localizedDescription);
        }
    };
    [pc createOfferWithDelegate:_sdpDelegate constraints:connection.options.constraints];
    
    
}

- (void)makeAnswer:(OGConnection *)connection {
    RTCPeerConnection * pc = connection.peerConnection;
    OGSessionDescriptionDelegate * delegate = [[OGSessionDescriptionDelegate alloc] initWithConnection:connection negotiator:self];
    
    [pc createAnswerWithDelegate:delegate constraints:connection.options.constraints];
    delegate.didCreateSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        if(!error) {
            
        }else{
            //TODO: webrtc error
            [connection emit:@"error" data:[NSError errorWithLocalizedDescription:error.localizedDescription]];
            DDLogError(@"Failed to create answer: %@",error.localizedDescription);
        }
    };
    delegate.didSetSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        if(!error) {
            OGMessage * answer = [OGMessage answerWithConnection:connection];
            [connection.provider send:answer connection:connection.identifier];
            
        }else{
            //TODO: webrtc error
            [connection emit:@"error" data:[NSError errorWithLocalizedDescription:error.localizedDescription]];
            DDLogError(@"Failed to set local description: %@",error.localizedDescription);
        }
    };
    
}

+(NSString *)identifierPrefix {
    return @"pc_";
}




-(RTCMediaStream *)addLocalAudioStream {
    RTCMediaStream* localStream = [_factory mediaStreamWithLabel:@"OGAUDIOSTR"];
    
    RTCAudioTrack* localAudioTrack = nil;
    
    localAudioTrack = [_factory audioTrackWithID:@"OGAUDIOSTR0"];
    if(localAudioTrack)
        [localStream addAudioTrack:localAudioTrack];
    return localStream;
    
    
}
-(RTCMediaStream *)addLocalVideoStream:(AVCaptureDevicePosition)direction {
    RTCMediaStream* localStream;
    // The iOS simulator doesn't provide any sort of camera capture
    // support or emulation (http://goo.gl/rHAnC1) so don't bother
    // trying to open a local stream.
    // TODO(tkchin): local video capture for OSX. See
    // https://code.google.com/p/webrtc/issues/detail?id=3417.
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    RTCVideoTrack* localVideoTrack = nil;
    localStream = [_factory mediaStreamWithLabel:@"OGVIDEOSTR"];
    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == direction) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the camera id");
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints *mediaConstraints = [OGPeerConfig defaultMediaConstraints];
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer
                                                        constraints:mediaConstraints];
    localVideoTrack = [_factory videoTrackWithID:@"OGVIDEOSTR0" source:videoSource];
    if (localVideoTrack) {
        
        [localStream addVideoTrack:localVideoTrack];
    }
#endif
    
    return localStream;
}
@end
