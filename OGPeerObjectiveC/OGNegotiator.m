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
#import "OGDataConnection.h"
#import "OGPeerConnectionDelegate.h"
#import "OGSessionDescriptionDelegate.h"
#import "RTCICECandidate.h"
@interface OGNegotiatorOptions ()
@end
@interface OGNegotiator ()
@property (nonatomic, strong) RTCPeerConnectionFactory * factory;
@property (nonatomic, strong) OGPeer * provider;
@property (nonatomic, strong) NSDictionary * pcs;
@end
@implementation OGNegotiator
-(instancetype)init {
    self = [super init];
    if(self) {
        _factory = [[RTCPeerConnectionFactory alloc] init];
    }
    return self;
    
}
-(RTCPeerConnection *)startConnection:(OGConnection *)connection options:(OGNegotiatorOptions *)options {
    RTCPeerConnection * pc = [self getPeerConnection:connection options:options];
    if (connection.type == OGConnectionTypeMedia && options.stream) {
        // Add the stream.
        [pc addStream:options.stream];
    }
    
    // Set the connection's PC.
    //connection.pc = connection.peerConnection = pc;
    // What do we need to do now?
    OGUtil * util = [OGUtil util];
    if (options.originator) {
        if (connection.type == OGConnectionTypeData) {
            
            // Create the datachannel.
            RTCDataChannelInit * config = [[RTCDataChannelInit alloc] init];
            RTCDataChannel * dc = [pc createDataChannelWithLabel:connection.label config:config];
            [((OGDataConnection *)connection) initialize:dc];
        }
        
        if (!util.supports.onnegotiationneeded) {
            [self makeOffer:connection];
        } else {
            [self handleSDP:OGMessageTypeOffer connection:connection sdp:options.sdp];
        }
    }
    return pc;
}
-(RTCPeerConnection *)getPeerConnection:(OGConnection *)connection options:(OGNegotiatorOptions *)options {
    
    if (!self.pcs[connection.typeAsString]) {
        //util.error(connection.type + ' is not a valid connection type. Maybe you overrode the `type` property somewhere.');
    }
    
    if (!((NSMutableDictionary *)self.pcs[connection.typeAsString])[connection.peer]) {
        ((NSMutableDictionary *)self.pcs[connection.typeAsString])[connection.peer] = @{};
    }
    NSDictionary * peerConnections = ((NSDictionary *)self.pcs[connection.typeAsString])[connection.peer];
    
    RTCPeerConnection * pc;
    // Not multiplexing while FF and Chrome have not-great support for it.
    /*if (options.multiplex) {
     ids = Object.keys(peerConnections);
     for (var i = 0, ii = ids.length; i < ii; i += 1) {
     pc = peerConnections[ids[i]];
     if (pc.signalingState === 'stable') {
     break; // We can go ahead and use this PC.
     }
     }
     } else */
    if (options.pc) { // Simplest case: PC id already provided for us.
        ((NSMutableDictionary *)self.pcs[connection.typeAsString])[connection.peer] = options.pc;
        pc = options.pc;
    }
    
    if (!pc || pc.signalingState != RTCSignalingStable) {
        pc = [self startPeerConnection:connection];
    }
    return pc;
}
- (RTCPeerConnection *)startPeerConnection:(OGConnection *)connection {
    
    OGUtil * util = [OGUtil util];
    NSString * identifier = [NSString stringWithFormat:@"%@%@",[OGNegotiator identifierPrefix],util.randomToken];
    NSArray *optionalConstraints = nil;
    
    
    
    if (connection.type == OGConnectionTypeData && !util.supports.sctp) {
        optionalConstraints = @[
                                [[RTCPair alloc] initWithKey:@"RtpDataChannels" value:@"true"]
                                ];
    } else if (connection.type == OGConnectionTypeMedia) {
        // Interop req for chrome.
        optionalConstraints = @[
                                [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                ];
    }
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
    
    OGPeerConnectionDelegate * delegate = [[OGPeerConnectionDelegate alloc] initWithConnection:connection negotiator:self];
    
    
    
    RTCPeerConnection * pc =  [_factory peerConnectionWithICEServers:connection.provider.options.config.iceServers constraints:constraints delegate:delegate];
    ((NSMutableDictionary *)((NSMutableDictionary *)self.pcs[connection.typeAsString])[connection.peer])[identifier] = pc;
    
    
    
    return pc;
}
/** Handle an SDP. */
- (void)handleSDP:(OGMessageType)type connection:(OGConnection *)connection sdp:(RTCSessionDescription *)sdp {
    RTCPeerConnection * pc = connection.peerConnection;
    OGSessionDescriptionDelegate * delegate = [[OGSessionDescriptionDelegate alloc] initWithConnection:connection negotiator:self];
    
    //util.log('Setting remote description', sdp);
    [pc setRemoteDescriptionWithDelegate:delegate sessionDescription:sdp];
    
    delegate.didSetSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        OGUtil * util = [OGUtil util];
        if(!error) {
            //[util.log('Set remoteDescription:', type, 'for:', connection.peer);
            
            if ([sdp.type isEqualToString:@"OFFER"]) {
                [self makeAnswer:connection];
            }
        }else{
            
            //            connection.provider.emitError('webrtc', err);
            //            util.log('Failed to setRemoteDescription, ', err);
        }
    };
}




/** Handle a candidate. */
- (void)handleCandidate:(OGConnection *)connection ice:(RTCICECandidate *)candidate {
    
    [connection.peerConnection addICECandidate:candidate];
    //util.log('Added ICE candidate for:', connection.peer);
}

-(void)cleanup:(OGConnection *)connection {
    //util.log('Cleaning up PeerConnection to ' + connection.peer);
    
    RTCPeerConnection * pc = connection.peerConnection;
    
    if (pc && pc.signalingState != RTCSignalingClosed) {
        [pc close];
        connection.peerConnection = nil;
    }
}

- (void)makeOffer:(OGConnection *)connection {
    RTCPeerConnection * pc = connection.peerConnection;
    OGSessionDescriptionDelegate * delegate = [[OGSessionDescriptionDelegate alloc] initWithConnection:connection negotiator:self];
    [pc createOfferWithDelegate:delegate constraints:connection.provider.constraints];
    delegate.didCreateSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        OGUtil * util = [OGUtil util];
        
        //if (!util.supports.sctp && _connection.type == OGConnectionTypeData && _connection.reliable) {
        //    offer.sdp = Reliable.higherBandwidthSDP(offer.sdp);
        //}
        if(!error) {
            
            
        }else{
            //connection.provider.emitError('webrtc', err);
            //util.log('Failed to createOffer, ', err);
        }
    };
    delegate.didSetSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        OGUtil * util = [OGUtil util];
        if(!error) {
            //util.log('Set localDescription: offer', 'for:', connection.peer);
            [connection.provider.socket send:@{
                                               @"type": @"OFFER",
                                               @"payload": @{
                                                       @"sdp": pc.localDescription.description,
                                                       @"type": connection.typeAsString,
                                                       @"label": connection.label,
                                                       @"connectionId": connection.identifier,
                                                       @"reliable": @(NO),
                                                       @"serialization": connection.serializationAsString,
                                                       @"metadata": connection.metadata,
                                                       @"browser": util.browser
                                                       },
                                               @"dst": connection.peer
                                               }];
        }else{
            
            //_connection.provider.emitError('webrtc', err);
            //util.log('Failed to setLocalDescription, ', err);
        }
    };
    
}

- (void)makeAnswer:(OGConnection *)connection {
    RTCPeerConnection * pc = connection.peerConnection;
    OGSessionDescriptionDelegate * delegate = [[OGSessionDescriptionDelegate alloc] initWithConnection:connection negotiator:self];
    
    [pc createAnswerWithDelegate:delegate constraints:connection.provider.constraints];
    delegate.didCreateSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        OGUtil * util = [OGUtil util];
        
        //if (!util.supports.sctp && _connection.type == OGConnectionTypeData && _connection.reliable) {
        //    offer.sdp = Reliable.higherBandwidthSDP(offer.sdp);
        //}
        if(!error) {
            
            
        }else{
            //connection.provider.emitError('webrtc', err);
            //util.log('Failed to createAnswer, ', err);
        }
    };
    delegate.didSetSessionDescription = ^(RTCPeerConnection * pc, RTCSessionDescription * sdp, NSError * error){
        OGUtil * util = [OGUtil util];
        if(!error) {
            //util.log('Set localDescription: answer', 'for:', connection.peer);
            [connection.provider.socket send:@{
                                               @"type": @"ANSWER",
                                               @"payload": @{
                                                       @"sdp": sdp.description,
                                                       @"type": connection.typeAsString,
                                                       @"connectionId": connection.identifier,
                                                       @"browser": util.browser
                                                       },
                                               @"dst": connection.peer
                                               }];
        }else{
            
            //_connection.provider.emitError('webrtc', err);
            //util.log('Failed to setLocalDescription, ', err);
        }
    };
    
}

+(NSString *)identifierPrefix {
    return @"pc_";
}
@end
