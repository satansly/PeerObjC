//
//  OGPeerConnectionDelegate.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGPeerConnectionDelegate.h"
#import "OGMediaConnection.h"
#import "OGDataConnection.h"
#import "OGMessage.h"
#import "OGUtil.h"
#import "OGNegotiator.h"



@implementation OGPeerConnectionDelegate
-(instancetype)initWithConnection:(OGConnection *)connection negotiator:(OGNegotiator *)negotiator {
    self = [super init];
    if(self) {
        NSAssert(connection != nil, @"Connection cannot be nil");
        NSAssert(negotiator != nil, @"Negotiator cannot be nil");
        
        _connection = connection;
        _negotiator = negotiator;
    }
    return self;
}
- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged {
    switch (stateChanged) {
        case RTCSignalingStable:
            DDLogDebug(@"Signaling state is stable for connection: %@",_connection.identifier);
            break;
        case RTCSignalingHaveLocalOffer:
            DDLogDebug(@"Connection: %@ has a local offer",_connection.identifier);
            break;
        case RTCSignalingHaveLocalPrAnswer:
            DDLogDebug(@"Connection: %@ has a local answer",_connection.identifier);
            break;
        case RTCSignalingHaveRemoteOffer:
            DDLogDebug(@"Connection: %@ has a remote offer",_connection.identifier);
            break;
        case RTCSignalingHaveRemotePrAnswer:
            DDLogDebug(@"Connection: %@ has a remote answer",_connection.identifier);
            break;
        case RTCSignalingClosed:
            DDLogDebug(@"Connection: %@ is closed",_connection.identifier);
        default:
            break;
    }
    //[_connection close];
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream {
    DDLogDebug(@"Received remote stream for connection: %@",_connection.identifier);
    OGMediaConnection * connection = (OGMediaConnection *)[_connection.provider getConnection:_connection.peer identifier:_connection.identifier];
    if (connection.type == OGConnectionTypeMedia) {
        [connection addStream:stream];
    }
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream {
    DDLogDebug(@"Removed remote stream for connection: %@",_connection.identifier);
    OGMediaConnection * connection = (OGMediaConnection *)[_connection.provider getConnection:_connection.peer identifier:_connection.identifier];
    if (connection.type == OGConnectionTypeMedia) {
        [connection removeStream:stream];
    }
}

// Triggered when renegotiation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {
    DDLogDebug(@"Renegotiating needed for connection: %@",_connection.identifier);
    if (peerConnection.signalingState == RTCSignalingStable) {
        if(_negotiator.options.originator) {
            [_negotiator makeOffer:_connection];
        }
    } else {
        DDLogDebug(@"Renegotiating needed but not performed for connection: %@. Connection is unstable",_connection.identifier);
    }
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState {
    switch (newState) {
        case RTCICEConnectionNew: {
            DDLogDebug(@"New ICE connection received for connection: %@",_connection.identifier);
        } break;
        case RTCICEConnectionClosed: {
            DDLogDebug(@"ICE connection closed for connection: %@",_connection.identifier);
        } break;
        case RTCICEConnectionFailed: {
            DDLogDebug(@"ICE connection failed for connection: %@. Closing connections to peer %@",_connection.identifier,_connection.provider.identifier);
            [_connection emit:@"error" data:[NSError errorWithLocalizedDescription:@"Negotiation of connection to %@ failed.",_connection.provider.identifier]];
            [_connection close];
        }
            break;
        case RTCICEConnectionChecking: {
            DDLogDebug(@"ICE connection checking for connection: %@",_connection.identifier);
        } break;
        case RTCICEConnectionCompleted: {
            DDLogDebug(@"ICE connection completed for connection: %@",_connection.identifier);
            
        } break;
        case RTCICEConnectionConnected: {
            DDLogDebug(@"ICE connection connected for connection: %@",_connection.identifier);
        } break;
        case RTCICEConnectionDisconnected: {
            DDLogDebug(@"ICE connection disconnected for connection: %@. Closing connections to peer %@",_connection.identifier,_connection.provider.identifier);
            [_connection close];
            
        }
            break;
        default:
            break;
    }
}

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState {
    switch (newState) {
        case RTCICEGatheringNew: {
            DDLogDebug(@"New ICE gathering state for connection: %@",_connection.identifier);
        } break;
        case RTCICEGatheringComplete: {
            DDLogDebug(@"ICE gathering complete for connection: %@",_connection.identifier);
        } break;
        case RTCICEGatheringGathering: {
            DDLogDebug(@"ICE gathering for connection: %@",_connection.identifier);
        } break;
        default:
            break;
            
    }
    
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate {
    DDLogDebug(@"ICE candidate received for connection: %@",_connection.identifier);
    OGMessage * candidated = [OGMessage candidateWithConnection:_connection candidate:candidate];
    [_connection.provider send:candidated connection:_connection.identifier];
    
}

// New data channel has been opened.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
    DDLogDebug(@"Received data channel for connection: %@",_connection.identifier);
    RTCDataChannel * dc = dataChannel;
    OGDataConnection * connection = (OGDataConnection *)[_connection.provider getConnection:_connection.peer identifier:_connection.identifier];
    [connection initialize:dc];
}
@end
