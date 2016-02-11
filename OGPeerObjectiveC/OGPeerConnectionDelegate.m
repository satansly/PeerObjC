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

@implementation OGPeerConnectionDelegate
-(instancetype)initWithConnection:(OGConnection *)connection negotiator:(OGNegotiator *)negotiator {
    return nil;
}
- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged {
    
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream {
    // util.log('Received remote stream');
    //RTCMediaStream * stream = stream;
    OGMediaConnection * connection = (OGMediaConnection *)[_connection.provider getConnection:_connection.provider.identifier identifier:_connection.identifier];
    // 10/10/2014: looks like in Chrome 38, onaddstream is triggered after
    // setting the remote description. Our connection object in these cases
    // is actually a DATA connection, so addStream fails.
    // TODO: This is hopefully just a temporary fix. We should try to
    // understand why this is happening.
    if (connection.type == OGConnectionTypeMedia) {
        [connection addStream:stream];
    }
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream {
    
}

// Triggered when renegotiation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {
    if (peerConnection.signalingState == RTCSignalingStable) {
        [_negotiator makeOffer:_connection];
    } else {
        //util.log('onnegotiationneeded triggered when not stable. Is another connection being established?');
    }
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState {
    switch (newState) {
        case RTCICEConnectionNew:
            
            break;
        case RTCICEConnectionClosed:
            break;
        case RTCICEConnectionFailed: {
            //            util.log('iceConnectionState is disconnected, closing connections to ' + peerId);
            [_connection handleError:[NSError errorWithDomain:@"com.ohgarage" code:1001 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Negotiation of connection to %@ failed.",_connection.provider.identifier]}]];
            [_connection close];
        }
            break;
        case RTCICEConnectionChecking:
            break;
        case RTCICEConnectionCompleted:
            //            pc.onicecandidate = util.noop;
            
            break;
        case RTCICEConnectionConnected:
            break;
        case RTCICEConnectionDisconnected: {
            //            util.log('iceConnectionState is disconnected, closing connections to ' + peerId);
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
        case RTCICEGatheringNew:
            break;
        case RTCICEGatheringComplete:
            break;
        case RTCICEGatheringGathering:
            break;
        default:
            break;
            
    }
    
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate {
    [_connection.provider.socket send:@{
                                        @"type": @"CANDIDATE",
                                        @"payload": @{
                                                @"candidate": candidate,
                                                @"type": _connection.typeAsString,
                                                @"connectionId": _connection.identifier
                                                },
                                        @"dst": _connection.provider.identifier
                                        }];
    
}

// New data channel has been opened.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
    //util.log('Received data channel');
    RTCDataChannel * dc = dataChannel;
    OGDataConnection * connection = (OGDataConnection *)[_connection.provider getConnection:_connection.provider.identifier identifier:_connection.identifier];
    [connection initialize:dc];
}
@end
