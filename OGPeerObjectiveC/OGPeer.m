//
//  OGPeer.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGPeer.h"
#import "OGCommon.h"
#import "OGMessage.h"
#import "OGUtil.h"
#import "RTCPair.h"
#import "RTCMediaConstraints.h"
#import "OGMediaConnection.h"
#import "OGDataConnection.h"
#import <EventEmitter/EventEmitter.h>

#define kMessageQueueCapacity 10
#define kDefaultHost @"0.peerjs.com"
#define kDefaultPath @"/"
#define kDefaultKey @"peerjs"
#define kWsURLTemplate @"%@://%@:%ld%@/peerjs?key=%@&id=%@&token=%@"
#define kDefaultSTUNServerUrl @"stun:stun.l.google.com:19302"


@implementation OGPeerConfig
+(OGPeerConfig *)config {
    OGPeerConfig * config = [[OGPeerConfig alloc] init];
    return config;
}
+(OGPeerConfig *)defaultConfig {
    OGPeerConfig * config = [OGPeerConfig config];
    config.iceServers =@[[[RTCICEServer alloc] initWithURI:[NSURL URLWithString:DEFAULT_STUN_SERVER] username:nil password:nil]];
    return config;
}
+(RTCMediaConstraints *)defaultConstraints {
    NSArray *optionalConstraints = @[
                                     [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                     ,[[RTCPair alloc] initWithKey:@"RtpDataChannels" value:@"true"]
                                     ];
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
    return constraints;
}
@end
@interface OGPeer ()<SRWebSocketDelegate>
@property (nonatomic, strong) NSMutableDictionary * lostMessages;
@property (nonatomic, strong) NSString * lastServerId;
@end
@implementation OGPeer
-(instancetype)initWithId:(NSString *)identifier options:(OGPeerOptions *)options {
    self = [super init];
    if(self) {
        _identifier = identifier;
        
        // Configurize options
        _options = options;
        
        OGUtil * util = [OGUtil util];
        
        // Set a custom log function if present
        //        if (options.logFunction) {
        //            util.setLogFunction(options.logFunction);
        //        }
        //        [util setLogLevel:(options.debug);
        //
        
        // Sanity checks
        // Ensure WebRTC supported
        if (!util.supports.audioVideo && !util.supports.data ) {
            [self delayedAbort:@"browser-incompatible"  message:@"The current browser does not support WebRTC"];
        }
        // Ensure alphanumeric id
        if (![util validateIdentifier:identifier]) {
            [self delayedAbort:@"invalid-id" message:[NSString stringWithFormat:@"ID '%@' is invalid",identifier]];
        }
        // Ensure valid key
        if (![util validateKey:options.key]) {
            [self delayedAbort:@"invalid-key" message:[NSString stringWithFormat:@"API KEY '%@' is invalid",options.key]];
        }
        // Ensure not using unsecure cloud server on SSL page
        if (options.secure && [options.host isEqualToString:util.host]) {
            [self delayedAbort:@"ssl-unavailable" message:@"The cloud server currently does not support HTTPS. Please run your own PeerServer to use HTTPS."];
        }
        //
        
        // States.
        _destroyed = false; // Connections have been killed
        _disconnected = false; // Connection to PeerServer killed but P2P connections still active
        _open = false; // Sockets and such are not yet open.
        //
        
        // References
        _connections = [NSMutableDictionary dictionary]; // DataConnections for this peer.
        _lostMessages = [NSMutableDictionary dictionary]; // src => [list of messages]
        //
        
        // Start the server connection
        [self initializeServerConnection];
        if (identifier) {
            [self initialize:identifier];
        } else {
            [self retrieveId:^(NSString * identifier){
                
            }];
        }
    }
    return self;
}
// Initialize the 'socket' (which is actually a mix of XHR streaming and
// websockets.)
-(void)initializeServerConnection {
    [self initialize:_identifier];
    
    [self.socket on:@"message" callback:^(id data) {
        [self handleMessage:data];
    }];
    [self.socket on:@"error" callback:^(NSError * error) {
        [self abort:@"socket-error" message:error.localizedDescription];
    }];
    [self.socket on:@"disconnected" notify:^{
        if(!_disconnected) {
            [self emitError:@"network" error:@"Lost connection to server"];
            [self disconnect];
        }
    }];
    [self.socket on:@"close" notify:^{
        if(!_disconnected) {
            [self abort:@"socket-closed" message:@"Underlying socket is already closed."];
        }
    }];
    [self.socket on:@"open" notify:^{
        [self drainMessages:@"TODO:connectionid"];
    }];
}
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    OGMessage * messageobj = [[OGMessage alloc] initWithDictionary:messageDict];
    [webSocket emit:@"message" data:messageobj];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    [webSocket emit:@"open"];
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [webSocket emit:@"error" data:error];
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [webSocket emit:@"close"];
}
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    
}

- (NSURL *)wsURL
{
    NSString *proto = _options.secure ? @"wss" : @"ws";
    NSString *token = [[OGUtil util] randomStringWithMaxLength:34];
    NSString *urlStr = [NSString stringWithFormat:kWsURLTemplate,
                        proto, _options.host,  (long)_options.port, _options.path, _options.key, _identifier, token];
#ifdef LOG
    NSLog(@"WebSocket URL: %@", urlStr);
#endif
    NSURL *url = [NSURL URLWithString:urlStr];
    return url;
}

/** Get a unique ID from the server via XHR. */
-(void)retrieveId:(void (^)(NSString * identifier))cb {
    OGUtil * util = [OGUtil util];
    
    
    NSString * protocol = _options.secure ? @"https://" : @"http://";
    NSString * queryString = [NSString stringWithFormat:@"?ts=%f%d",[[NSDate date] timeIntervalSince1970],rand()];
    NSString * url = [NSString stringWithFormat:@"%@%@:%@%@%@/id%@",protocol, _options.host,_options.port,
                      _options.path, _options.key,queryString];
    
    // If there's no ID we need to wait for one before trying to init socket.
    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error) {
            //util.error('Error retrieving ID', e);
            NSString * pathError = @"";
            if ([_options.path isEqualToString:@"/"] && ![_options.host isEqualToString:util.host]) {
                pathError = @"If you passed in a `path` to your self-hosted PeerServer, you\'ll also need to pass in that same path when creating a new  Peer.";
            }
            [self abort:@"server-error"  message:[NSString stringWithFormat:@"Could not get an ID from the server. %@", pathError]];
        }else{
            NSHTTPURLResponse * resp = (NSHTTPURLResponse *)response;
            if (resp.statusCode != 200) {
                return;
            }
            NSString * ident = [NSString stringWithUTF8String:[data bytes]];
            [self initialize:ident];
        }
    }];
    [task resume];
}

/** Initialize a connection with the server. */
-(void)initialize:(NSString *)identifier {
    _socket = [[SRWebSocket alloc] initWithURL:[self wsURL]];
    _socket.delegate = self;
};

/** Handles messages from the server. */
-(void)handleMessage:(OGMessage *)message {
    OGMessageType type = message.type;
    OGMessagePayload * payload = message.payload;
    NSString * peer = message.source;
    OGConnection * connection;
    switch (type) {
        case OGMessageTypeOffer: {
            NSString * connectionId = payload.connectionId;
            connection = [self getConnection:peer identifier:connectionId];
            
            if (connection) {
                //util.warn('Offer received for existing Connection ID:', connectionId);
                
            } else {
                // Create a new connection.
                if (payload.type == OGConnectionTypeMedia) {
                    OGMediaConnectionOptions * options = [[OGMediaConnectionOptions alloc] init];
                    options.payload = payload;
                    options.connectionId = connectionId;
                    options.metadata = payload.metadata;
                    connection = [[OGMediaConnection alloc] initWithPeer:peer provider:self options:options];
                    [self addConnection:peer connection:connection];
                    [self emit:@"call"  data:connection];
                } else if (payload.type == OGConnectionTypeData) {
                    OGDataConnectionOptions * options = [[OGDataConnectionOptions alloc] init];
                    options.connectionId = connectionId;
                    options.payload = payload;
                    options.metadata = payload.metadata;
                    options.label = payload.label;
                    options.serialization = payload.serialization;
                    options.reliable = payload.reliable;
                    
                    connection = [[OGDataConnection alloc] initWithPeer:peer provider:self options:options];
                    [self addConnection:peer connection:connection];
                    [self emit:@"connection" data:connection];
                } else {
                    //util.warn('Received malformed connection type:', payload.type);
                    return;
                }
                // Find messages.
                NSArray * messages = [self getMessages:connectionId];
                for (int i = 0; i < messages.count; i++) {
                    [connection handleMessage:messages[i]];
                }
            }
            break;
        }
            
        case OGMessageTypeOpen: {
            [self emit:@"open" data:_identifier];
            _open = true;
            break;
        }
        case OGMessageTypeError: {
            [self abort:@"server-error" message:payload.msg];
            break;
        }
        case OGMessageTypeIdTaken: {
            [self abort:@"unavailable-id" message:[NSString stringWithFormat:@"ID '%@' is taken",_identifier]];
            break;
        }
        case OGMessageTypeInvalidKey: {
            [self abort:@"invalid-key" message:[NSString stringWithFormat:@"API KEY '%@' is invalid",_options.key]];
            break;
        }
        case OGMessageTypeLeave: {
            //util.log('Received leave message from', peer);
            [self cleanupPeer:peer];
            break;
        }
        case OGMessageTypeExpire: {
            [self emitError:@"peer-unavailable" error:[NSString stringWithFormat:@"Could not connect to peer %@", peer]];
            break;
        }
        default: {
            if (!payload) {
                //util.warn('You received a malformed message from ' + peer + ' of type ' + type);
                return;
            }
            
            NSString * ident = payload.connectionId;
            connection = [self getConnection:peer identifier:ident];
            
            if (connection && connection.peerConnection) {
                // Pass it on.
                [connection handleMessage:message];
            } else if (ident) {
                // Store for possible later use
                [self storeMessage:ident message:message];
            } else {
                //util.warn('You received an unrecognized message:', message);
            }
            
            break;
        }
            
    }
    
}

/** Stores messages without a set up connection, to be claimed later. */
-(void)storeMessage:(NSString *)connectionId message:(OGMessage *)message {
    if (!_lostMessages[connectionId]) {
        _lostMessages[connectionId] = @[];
    }
    [_lostMessages[connectionId] addObject:message];
};

/** Retrieve messages from lost message store */
-(NSArray *)getMessages:(NSString *)connectionId {
    NSMutableArray * messages = _lostMessages[connectionId];
    if (messages) {
        _lostMessages[connectionId] = nil;
        return messages;
    } else {
        return @[];
    }
};
-(void)drainMessages:(NSString *)connectionId {
    for (NSDictionary *msg in _lostMessages) {
        [_socket send:msg];
    }
}
/**
 * Returns a DataConnection to the specified peer. See documentation for a
 * complete list of options.
 */
-(OGDataConnection *)connect:(NSString *)peer options:(OGDataConnectionOptions *)options {
    if (_disconnected) {
        //util.warn('You cannot connect to a new Peer because you called ' +
        //          '.disconnect() on this Peer and ended your connection with the ' +
        //          'server. You can create a new Peer to reconnect, or call reconnect ' +
        //         'on this peer if you believe its ID to still be available.');
        [self emitError:@"disconnected" error:@"Cannot connect to new Peer after disconnecting from server."];
        return nil;
    }
    OGDataConnection * connection = [[OGDataConnection alloc] initWithPeer:peer provider:self options:options];
    [self addConnection:peer connection:connection];
    return connection;
};

/**
 * Returns a MediaConnection to the specified peer. See documentation for a
 * complete list of options.
 */
-(OGMediaConnection *)call:(NSString *)peer stream:(RTCMediaStream *)stream options:(OGMediaConnectionOptions *)options {
    if (_disconnected) {
        //util.warn('You cannot connect to a new Peer because you called ' +
        //          '.disconnect() on this Peer and ended your connection with the ' +
        //          'server. You can create a new Peer to reconnect.');
        [self emitError:@"disconnected" error:@"Cannot connect to new Peer after disconnecting from server."];
        return nil;
    }
    if (!stream) {
        //util.error('To call a peer, you must provide a stream from your browser\'s `getUserMedia`.');
        return nil;
    }
    options.stream = stream;
    OGMediaConnection * call = [[OGMediaConnection alloc] initWithPeer:peer provider:self options:options];
    [self addConnection:peer connection:call];
    return call;
};

/** Add a data/media connection to this peer. */
-(void)addConnection:(NSString *)peer connection:(OGConnection *)connection {
    if (!_connections[peer]) {
        _connections[peer] = @[];
    }
    [_connections[peer] addObject:connection];
};

/** Retrieve a data/media connection for this peer. */
-(OGConnection *)getConnection:(NSString *)peer identifier:(NSString *)identifier {
    NSMutableArray * connections = _connections[peer];
    if (!connections) {
        return nil;
    }
    for (int i = 0; i < connections.count; i++) {
        if ([((OGConnection *)connections[i]).identifier isEqualToString:identifier]) {
            return connections[i];
        }
    }
    return nil;
};

-(void)delayedAbort:(NSString *)type message:(NSString *)message {
    //util.setZeroTimeout(function(){
    [self abort:type message:message];
    //});
};

/**
 * Destroys the Peer and emits an error message.
 * The Peer is not destroyed if it's in a disconnected state, in which case
 * it retains its disconnected state and its existing connections.
 */
-(void)abort:(NSString *)type message:(NSString *)message {
    //util.error('Aborting!');
    if (!_lastServerId) {
        [self destroy];
    } else {
        [self disconnect];
    }
    [self emitError:type error:message];
}

/** Emits a typed error message. */
-(void)emitError:(NSString *)type error:(NSString *)error {
    //util.error('Error:', err);
    [self emit:@"error" data:[NSError errorWithDomain:@"com.ohgarage" code:1001 userInfo:@{NSLocalizedDescriptionKey:error}]];
}

/**
 * Destroys the Peer: closes all active connections as well as the connection
 *  to the server.
 * Warning: The peer can no longer create or accept connections after being
 *  destroyed.
 */
-(void)destroy {
    if (_destroyed) {
        [self cleanup];
        [self disconnect];
        _destroyed = true;
    }
}


/** Disconnects every connection on this peer. */
-(void)cleanup {
    if (_connections) {
        NSArray * peers = _connections.allKeys;
        for (int i = 0; i < peers.count; i++) {
            [self cleanupPeer:peers[i]];
        }
    }
    [self emit:@"close"];
};

/** Closes all connections to this peer. */
-(void)cleanupPeer:(NSString *)peer {
    NSMutableArray * connections = _connections[peer];
    for (int j = 0; j < connections.count; j++) {
        [((OGConnection *)connections[j]) close];
    }
};

/**
 * Disconnects the Peer's connection to the PeerServer. Does not close any
 *  active connections.
 * Warning: The peer can no longer create or accept connections after being
 *  disconnected. It also cannot reconnect to the server.
 */
-(void)disconnect {
    //TODO util.setZeroTimeout(function(){
    if (!_disconnected) {
        _disconnected = true;
        _open = false;
        if (_socket) {
            [_socket close];
        }
        [self emit:@"disconnected" data:_identifier];
        _lastServerId = _identifier;
        _identifier = nil;
    }
}
//);


/** Attempts to reconnect with the same ID. */
-(void)reconnect {
    if (_disconnected && !_destroyed) {
        //util.log('Attempting reconnection to server with ID ' + this._lastServerId);
        _disconnected = false;
        [self initializeServerConnection];
        [self initialize:_lastServerId];
    } else if (_destroyed) {
        @throw  [NSError errorWithDomain:@"com.ohgarage" code:1001 userInfo:@{NSLocalizedDescriptionKey:@"This peer cannot reconnect to the server. It has already been destroyed."}];
    } else if (!_disconnected && !_open) {
        // Do nothing. We're still connecting the first time.
        //util.error('In a hurry? We\'re still trying to make the initial connection!');
    } else {
        @throw [NSError errorWithDomain:@"com.ohgarage" code:1001 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Peer '%@' cannot reconnect because it is not disconnected from the server!",_identifier]}];
    }
};

/**
 * Get a list of available peer IDs. If you're running your own server, you'll
 * want to set allow_discovery: true in the PeerServer options. If you're using
 * the cloud server, email team@peerjs.com to get the functionality enabled for
 * your key.
 */
-(void)listAllPeers:(void (^)(NSArray * array))cb {
    
    NSString * protocol = _options.secure ? @"https://" : @"http://";
    NSString * queryString = [NSString stringWithFormat:@"?ts=%f%d",[[NSDate date] timeIntervalSince1970],rand()];
    NSString * url = [NSString stringWithFormat:@"%@%@:%@%@%@/peers%@",protocol, _options.host,_options.port,
                      _options.path, _options.key,queryString];
    
    // If there's no ID we need to wait for one before trying to init socket.
    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error) {
            //util.error('Error retrieving ID', e);
            
            [self abort:@"server-error"  message:@"Could not get peers from the server."];
        }else{
            NSHTTPURLResponse * resp = (NSHTTPURLResponse *)response;
            if (resp.statusCode == 401) {
                OGUtil * util = [OGUtil util];
                NSString * helpfulError = @"";
                if (![_options.host isEqualToString:util.host]) {
                    helpfulError = @"It looks like you\'re using the cloud server. You can email team@peerjs.com to enable peer listing for your API key.";
                } else {
                    helpfulError = @"You need to enable `allow_discovery` on your self-hosted PeerServer to use this feature.";
                }
                cb(@[]);
                @throw [NSError errorWithDomain:@"oh.garage" code:1001 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"It doesn\'t look like you have permission to list peers IDs. %@", helpfulError]}];
            } else if (resp.statusCode != 200) {
                cb(@[]);
            } else {
                NSError * error;
                NSArray * list = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                cb(list);
            }
        }
    }];
    [task resume];
    
}

@end
