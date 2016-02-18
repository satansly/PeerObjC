//
//  OGPeer.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <SocketRocket/SRWebSocket.h>
#import "OGCommon.h"
#import "RTCVideoTrack.h"
#import "RTCSessionDescription.h"
#import "RTCTypes.h"
#import "RTCEAGLVideoView.h"
#import "RTCMediaStream.h"
#import "RTCDataChannel.h"
#import "RTCPeerConnection.h"
#import "RTCICEServer.h"
#import "OGDelegateDispatcher.h"
#import <CocoaLumberjack/CocoaLumberjack.h>


@class OGPeer;
@class OGPeerConfig;
@class OGICEServer;
@class OGDataConnection;
@class OGMediaConnection;
@class OGMediaConnectionOptions;
@class OGDataConnectionOptions;
@class OGConnection;
@class OGMessage;

@protocol OGPeerDelegate<NSObject>
-(void)peerDidOpen:(OGPeer *)peer;
-(void)peer:(OGPeer *)peer didReceiveError:(NSError *)error;
-(void)peer:(OGPeer *)peer didReceiveCall:(OGMediaConnection *)connection;
-(void)peer:(OGPeer *)peer didReceiveConnection:(OGDataConnection *)connection;
-(void)peerDidClose:(OGPeer *)peer;
-(void)peer:(OGPeer *)peer didDisconnectPeer:(NSString *)identifier;
@end


/**
 *  @brief Options associated with a peer object at the time of initalizing
 */
@interface OGPeerOptions : NSObject
/**
 *  @brief Key issued by peerjs server for connecting
 */
@property (nonatomic, strong) NSString * key;
/**
 *  @brief Host address of the peerjs server. Default used if this is nil.
 */
@property (nonatomic, strong) NSString * host;
/**
 *  @brief Path of the peerjs server. Default used if this is nil.
 */
@property (nonatomic, strong) NSString * path;
/**
 *  @brief Port address of the peerjs server. Default used if this is nil.
 */
@property (nonatomic, strong) NSNumber * port;
/**
 *  @brief Is connection over secure channel
 */
@property (nonatomic, assign) BOOL secure;
/**
 *  @brief Config object for ICE servers
 */
@property (nonatomic, strong) OGPeerConfig * config;

@property (nonatomic, assign) DDLogLevel debugLevel;
@end
/**
 *  @brief Provides ICE server addresses/credentials when creating peer connection
 */
@interface OGPeerConfig : NSObject
/**
 *  @brief Array of ICE server objects
 */
@property (nonatomic, strong) NSArray<RTCICEServer *> * iceServers;
/**
 *  @brief Default config set with default ICE server(s)
 *
 *  @return Default config set with default ICE server(s)
 */
+(OGPeerConfig *)defaultConfig;

/**
 *  @brief Default peer connection constraints
 *
 *  @return Default peer connection constraints
 */
+(RTCMediaConstraints *)defaultConstraints;
/**
 *  @brief Default answer constraints for incoming peer connection
 *
 *  @return Default answer constraints for incoming peer connection
 */
+(RTCMediaConstraints *)defaultAnswerConstraints;
/**
 *  @brief Default offer constraints for outgoing peer connection
 *
 *  @return Default offer constraints for outgoing peer connection
 */
+(RTCMediaConstraints *)defaultOfferConstraints;
/**
 *  @brief Default media constraints
 *
 *  @return Default media constraints
 */
+(RTCMediaConstraints *)defaultMediaConstraints;
@end

/**
 *  @brief Manages peers and peer connections.
 */
@interface OGPeer : OGDelegateDispatcher<SRWebSocketDelegate>
/**
 *  @brief Identifier of this peer object
 */
@property (nonatomic, strong) NSString * identifier;
/**
 *  @brief Currently active connections(media and data)
 */
@property (nonatomic, strong) NSMutableDictionary * connections;
/**
 *  @brief Options used to initialize peer object
 */
@property (nonatomic, strong) OGPeerOptions * options;
/**
 *  @brief Socket object performing messages exchange for connection negotiation
 */
@property (nonatomic, strong) SRWebSocket * socket;
/**
 *  @brief Is peer disconnected
 */
@property (nonatomic, assign) BOOL disconnected;
/**
 *  @brief Is peer destroyed
 */
@property (nonatomic, assign) BOOL destroyed;
/**
 *  @brief Is peer open and ready to make connections
 */
@property (nonatomic, assign) BOOL open;

/**
 *  @brief Initalizes peer object with given identifier and options
 *
 *  @param identifier Identifier assigned to this peer object
 *  @param options    Options used to initialize peer object
 *
 *  @return Initalized peer object with given identifier and options
 */
-(instancetype)initWithId:(NSString *)identifier options:(OGPeerOptions *)options;
/**
 *  @brief Initalizes peer object with given identifier and options
 *
 *  @param identifier Identifier assigned to this peer object
 *  @param options    Options used to initialize peer object
 *  @param socket     Socket object
 *
 *  @return Initalized peer object with given identifier and options
 */
-(instancetype)initWithId:(NSString *)identifier options:(OGPeerOptions *)options socket:(SRWebSocket *)socket;
/**
 *  @brief Connects to the given peer and connection options
 *
 *  @param peer    Peer identifier
 *  @param options Options used to initialize connection
 *
 *  @return Initialized instance of data connection
 */
-(OGDataConnection *)connect:(NSString *)peer options:(OGDataConnectionOptions *)options;
/**
 *  @brief Call method to initialize socket and handlers for socket
 */
-(void)initializeServerConnection;
/**
 *  @brief Connects call to given peer and connection options
 *
 *  @param identifier Peer identifier
 *  @param options    Options used to initialize connection
 *
 *  @return Initialized instance of media connection
 */
-(OGMediaConnection *)call:(NSString *)identifier options:(OGMediaConnectionOptions *)options;

/**
 *  @brief Retrieve a data/media connection for this peer
 *
 *  @param peerId       Peer identifier
 *  @param connectionId Connection identifier
 *
 *  @return Established connection with given peer and connection
 */
-(OGConnection *)getConnection:(NSString *)peerId identifier:(NSString *)connectionId;


/**
 * @brief Get a list of available peer IDs. If you're running your own server, you'll
 * want to set allow_discovery: true in the PeerServer options. If you're using
 * the cloud server, email team@peerjs.com to get the functionality enabled for
 * your key.
 */
-(void)listAllPeers:(void (^)(NSArray * array))cb;
/**
 *  @brief Get queued messages to given peer
 *
 *  @param peer Peer identifier
 *
 *  @return Array of queued messages
 */
-(NSArray *)getMessages:(NSString *)peer;

/**
 *  @brief Sends message to given connection
 *
 *  @param message      Message object
 *  @param connectionId Connection identifier
 */
-(void)send:(OGMessage  *)message connection:(NSString *)connectionId;

/**
 *  @brief  * Disconnects the Peer's connection to the PeerServer. Does not close any
 *  active connections.
 *  Warning: The peer can no longer create or accept connections after being
 *  disconnected. It also cannot reconnect to the server.
 */
-(void)disconnect;
/**
 *  @brief Attempts to reconnect with the same ID.
 */
-(void)reconnect;
/**
 *  @brief Destroys the Peer: closes all active connections as well as the connection
 *  to the server.
 *  Warning: The peer can no longer create or accept connections after being
 *  destroyed.
 */
-(void)destroy;


@end

