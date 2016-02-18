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

@implementation OGPeerConfig
+(OGPeerConfig *)config {
    OGPeerConfig * config = [[OGPeerConfig alloc] init];
    return config;
}
+(OGPeerConfig *)defaultConfig {
    OGPeerConfig * config = [OGPeerConfig config];
    RTCICEServer * server = [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:DEFAULT_STUN_SERVER] username:@"" password:@""];
    config.iceServers =@[server];
    return config;
}
+(RTCMediaConstraints *)defaultConstraints {
    NSArray *optionalConstraints = @[
                                     [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                     ];
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:optionalConstraints];
    return constraints;
}
+(RTCMediaConstraints *)defaultAnswerConstraints {
    return [OGPeerConfig defaultOfferConstraints];
}
+(RTCMediaConstraints *)defaultOfferConstraints {
    NSArray *mandatoryConstraints = @[
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]
                                      ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
}
+(RTCMediaConstraints *)defaultMediaConstraints {
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:nil];
    return constraints;
    
}
@end
@implementation OGPeerOptions

@end
@interface OGPeer ()
@property (nonatomic, strong) NSMutableDictionary * lostMessages;
@property (nonatomic, strong) NSString * lastServerId;

@end
@implementation OGPeer
-(instancetype)initWithId:(NSString *)identifier options:(OGPeerOptions *)options socket:(SRWebSocket *)socket {
    self = [self initWithId:identifier options:options];
    if(self) {
        _socket = socket;
    }
    return self;
}
-(instancetype)initWithId:(NSString *)identifier options:(OGPeerOptions *)options {
    self = [super init];
    if(self) {
        _identifier = identifier;
        
        // Configurize options
        _options = options;
        OGUtil * util = [OGUtil util];
        
        if(!_options.host)
            _options.host = util.host;
        if(!_options.port)
            _options.port = util.port;
        if(!_options.path)
            _options.path = @"";
        
        ddLogLevel = _options.debugLevel;
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        
        [DDLog addLogger:fileLogger];
        
        
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
        
        
        [self setupObservers];
    }
    return self;
}
-(void)setupObservers {
    DDLogDebug(@"Setting up observers to application notifications");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
}
// Initialize the 'socket' (which is actually a mix of XHR streaming and
// websockets.)
-(void)initializeServerConnection {
    
    
    // Start the server connection
    
    if (!_identifier) {
        [self retrieveId:^(NSString * identifier){
            
        }];
        return;
    }
    
    DDLogDebug(@"Initializing server connection");
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
        [self drainMessages];
    }];
    
    
    
    
}
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    OGMessage * messageobj = [[OGMessage alloc] initWithDictionary:messageDict];
    DDLogDebug(@"Socket received data %@",messageDict);
    [webSocket emit:@"message" data:messageobj];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    DDLogDebug(@"Socket opened");
    [webSocket emit:@"open"];
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    DDLogError(@"Socket received error %@",[error localizedDescription]);
    [webSocket emit:@"error" data:error];
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    DDLogDebug(@"Socket closed");
    [webSocket emit:@"close"];
}
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    DDLogDebug(@"Socket received pong %@",pongPayload);
}

- (NSURL *)wsURL
{
    NSString *proto = _options.secure ? @"wss" : @"ws";
    NSString *token = [[OGUtil util] randomStringWithMaxLength:34];
    NSString *urlStr = [NSString stringWithFormat:kWsURLTemplate,
                        proto, _options.host,  _options.port.longValue, _options.path, _options.key, _identifier, token];
    DDLogDebug(@"WebSocket URL: %@", urlStr);
    NSURL *url = [NSURL URLWithString:urlStr];
    return url;
}

/** Get a unique ID from the server via XHR. */
-(void)retrieveId:(void (^)(NSString * identifier))cb {
    DDLogDebug(@"Retreiving identifier from server");
    OGUtil * util = [OGUtil util];
    
    
    NSString * protocol = _options.secure ? @"https://" : @"http://";
    NSString * queryString = [NSString stringWithFormat:@"?ts=%f%d",[[NSDate date] timeIntervalSince1970],rand()];
    NSString * url = [NSString stringWithFormat:@"%@%@:%@%@%@/id%@",protocol, _options.host,_options.port,
                      _options.path, _options.key,queryString];
    
    // If there's no ID we need to wait for one before trying to init socket.
    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error) {
            DDLogError(@"Error retreiving identifier from server : %@",[error localizedDescription]);
            NSString * pathError = @"";
            if ([_options.path isEqualToString:@"/"] && ![_options.host isEqualToString:util.host]) {
                pathError = @"If you passed in a `path` to your self-hosted PeerServer, you\'ll also need to pass in that same path when creating a new  Peer.";
            }
            [self abort:@"server-error"  message:[NSString stringWithFormat:@"Could not get an ID from the server. %@", pathError]];
        }else{
            NSHTTPURLResponse * resp = (NSHTTPURLResponse *)response;
            if (resp.statusCode != 200) {
                DDLogWarn(@"Retreiving identifier from server");
                return;
            }
            
            NSString * ident = [NSString stringWithUTF8String:[data bytes]];
            DDLogDebug(@"Retreiving identifier from server");
            _identifier = ident;
            [self initializeServerConnection];
        }
    }];
    [task resume];
}

/** Initialize a connection with the server. */
-(void)initialize:(NSString *)identifier {
    DDLogDebug(@"Initializing connection with server");
    if(!_socket) {
        _socket = [[SRWebSocket alloc] initWithURL:[self wsURL]];
        _socket.delegate = self;
        
    }
    [_socket open];
}

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
                DDLogWarn(@"Offer received for existing Connection ID: %@", connectionId);
            } else {
                
                // Create a new connection.
                if (payload.type == OGConnectionTypeMedia) {
                    DDLogDebug(@"Received a media connection from peer %@",peer);
                    OGMediaConnectionOptions * options = [[OGMediaConnectionOptions alloc] init];
                    options.payload = payload;
                    options.connectionId = connectionId;
                    options.metadata = payload.metadata;
                    connection = [[OGMediaConnection alloc] initWithPeer:peer provider:self options:options];
                    [self addConnection:peer connection:connection];
                    [self emit:@"call"  data:connection];
                    [self perform:@selector(peer:didReceiveCall:) withArgs:@[self,connection]];
                    [connection initialize];
                    
                } else if (payload.type == OGConnectionTypeData) {
                    DDLogDebug(@"Received a data connection from peer %@", peer);
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
                    [self perform:@selector(peer:didReceiveConnection:) withArgs:@[self,connection]];
                } else {
                    DDLogWarn(@"Received malformed connection type: %@", [[OGUtil util] stringFromConnectionType:payload.type]);
                    return;
                }
                DDLogDebug(@"Handling queued messages");
                // Find messages.
                NSArray * messages = [self getMessages:connectionId];
                for (int i = 0; i < messages.count; i++) {
                    [connection handleMessage:messages[i]];
                }
            }
            break;
        }
            
        case OGMessageTypeOpen: {
            DDLogDebug(@"Received open message");
            [self emit:@"open" data:_identifier];
            [self perform:@selector(peerDidOpen:) withArgs:@[self]];
            [self drainMessages:payload.connectionId];
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
            DDLogDebug(@"Received leave message from %@", peer);
            [self cleanupPeer:peer];
            break;
        }
        case OGMessageTypeExpire: {
            [self emitError:@"peer-unavailable" error:[NSString stringWithFormat:@"Could not connect to peer %@", peer]];
            break;
        }
        default: {
            if (!payload) {
                DDLogWarn(@"You received a malformed message from %@ of type %@",peer,[[OGUtil util] stringFromMessageType:type]);
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
                DDLogWarn(@"You received an unrecognized message: %@", [message dictionary]);
            }
            
            break;
        }
            
    }
    
}

/** Stores messages without a set up connection, to be claimed later. */
-(void)storeMessage:(NSString *)connectionId message:(OGMessage *)message {
    DDLogDebug(@"Storing message without a setup connection. To be claimed later");
    if (!_lostMessages[connectionId]) {
        _lostMessages[connectionId] = [NSMutableArray array];
    }
    [_lostMessages[connectionId] addObject:message];
}

/** Retrieve messages from lost message store */
-(NSArray *)getMessages:(NSString *)connectionId {
    DDLogDebug(@"Retrieving messages from lost message store");
    NSMutableArray * messages = _lostMessages[connectionId];
    if (messages) {
        _lostMessages[connectionId] = nil;
        return messages;
    } else {
        return @[];
    }
}
-(void)send:(OGMessage  *)message connection:(NSString *)connectionId {
    DDLogDebug(@"Sending message for connection: %@",connectionId);
    //TODO : Looks like send pending and received pending messages are getting mixed up here. FIX IT!
    if(_socket.readyState == SR_OPEN) {
        DDLogDebug(@"Sending data %@",[message dictionary]);
        [_socket send:[message JSONData]];
    }else{
        NSMutableArray * messages = _lostMessages[connectionId];
        [messages addObject:message];
    }
}
-(void)drainMessages:(NSString *)connectionId {
    DDLogDebug(@"Flushing pending messages to connection %@",connectionId);
    NSArray * messages = _lostMessages[connectionId];
    for (OGMessage *msg in messages) {
        [_socket send:[msg JSONData]];
    }
    
}
-(void)drainMessages {
    DDLogDebug(@"Flushing all pending messages to all connections");
    for(NSString * connectionId in _lostMessages.allKeys) {
        NSArray * messages = _lostMessages[connectionId];
        for (OGMessage *msg in messages) {
            [_socket send:[msg JSONData]];
        }
    }
}
/**
 * Returns a DataConnection to the specified peer. See documentation for a
 * complete list of options.
 */
-(OGDataConnection *)connect:(NSString *)peer options:(OGDataConnectionOptions *)options {
    DDLogDebug(@"Attempting to connect to peer %@",peer);
    if (_disconnected) {
        DDLogWarn(@"You cannot connect to a new Peer because you called .disconnect on this Peer and ended your connection with the server. You can create a new Peer to reconnect, or call reconnect on this peer if you believe its ID to still be available.");
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
-(OGMediaConnection *)call:(NSString *)peer options:(OGMediaConnectionOptions *)options {
    DDLogDebug(@"Attempting to disconnect peer %@", peer);
    if (_disconnected) {
        DDLogWarn(@"You cannot connect to a new Peer because you called  disconnect on this Peer and ended your connection with the server. You can create a new Peer to reconnect.");
        [self emitError:@"disconnected" error:@"Cannot connect to new Peer after disconnecting from server."];
        return nil;
    }
    
    OGMediaConnection * call = [[OGMediaConnection alloc] initWithPeer:peer provider:self options:options];
    [self addConnection:peer connection:call];
    return call;
};

/** Add a data/media connection to this peer. */
-(void)addConnection:(NSString *)peer connection:(OGConnection *)connection {
    DDLogDebug(@"Adding connection to connection store");
    if (!_connections[peer]) {
        _connections[peer] = [NSMutableArray array];
    }
    [connection on:@"close" notify:^{
        [self cleanupPeer:peer connection:connection.identifier];
    }];
    [_connections[peer] addObject:connection];
};

/** Retrieve a data/media connection for this peer. */
-(OGConnection *)getConnection:(NSString *)peer identifier:(NSString *)identifier {
    DDLogDebug(@"Retrieving connection from connection store");
    NSMutableArray * connections = _connections[peer];
    if (!connections) {
        DDLogDebug(@"No connections to peer %@",peer);
        return nil;
    }
    for (int i = 0; i < connections.count; i++) {
        OGConnection * connection = (OGConnection *)connections[i];
        if ([connection.identifier isEqualToString:identifier]) {
            return connections[i];
        }
    }
    DDLogDebug(@"No connections with identifier to peer %@",peer);
    return nil;
};

-(void)delayedAbort:(NSString *)type message:(NSString *)message {
    DDLogWarn(@"Aborting with delay. \nType %@ \nMessage %@",type,message);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self abort:type message:message];
    });
};

/**
 * Destroys the Peer and emits an error message.
 * The Peer is not destroyed if it's in a disconnected state, in which case
 * it retains its disconnected state and its existing connections.
 */
-(void)abort:(NSString *)type message:(NSString *)message {
    DDLogWarn(@"Aborting. \nType %@ \nMessage %@",type,message);
    if (!_lastServerId) {
        [self destroy];
    } else {
        [self disconnect];
    }
    [self emitError:type error:message];
}

/** Emits a typed error message. */
-(void)emitError:(NSString *)type error:(NSString *)error {
    DDLogError(@"Error: %@", error);
    NSError * err = [NSError errorWithLocalizedDescription:error];
    [self emit:@"error" data:err];
    [self perform:@selector(peer:didReceiveError:) withArgs:@[self,err]];
}


-(void)destroy {
    if (!_destroyed) {
        DDLogDebug(@"Destroying");
        [self cleanup];
        [self disconnect];
        _destroyed = true;
    }
}


/** Disconnects every connection on this peer. */
-(void)cleanup {
    if (_connections) {
        DDLogDebug(@"Cleaning up all connections");
        NSArray * peers = _connections.allKeys;
        for (int i = 0; i < peers.count; i++) {
            [self cleanupPeer:peers[i]];
        }
    }
    [self emit:@"close"];
    [self perform:@selector(peerDidClose:) withArgs:@[self]];
};
-(void)cleanupPeer:(NSString *)peer connection:(NSString *)connectionid {
    DDLogDebug(@"Closing connection %@ to peer %@",connectionid, peer);
    NSMutableArray * connections = _connections[peer];
    for (int j = 0; j < connections.count; j++) {
        OGConnection * connection = (OGConnection *)connections[j];
        if([connection.identifier isEqualToString:connectionid]) {
            [connection close];
            [connections removeObjectAtIndex:j];
        }
    }
}
/** Closes all connections to this peer. */
-(void)cleanupPeer:(NSString *)peer {
    DDLogDebug(@"Closing connections to peer %@",peer);
    NSMutableArray * connections = _connections[peer];
    for (int j = 0; j < connections.count; j++) {
        [((OGConnection *)connections[j]) close];
        [connections removeObjectAtIndex:j];
    }
    
};


-(void)disconnect {
    if (!_disconnected) {
        DDLogDebug(@"Disconnecting socket and cleaning up");
        _disconnected = true;
        _open = false;
        if (_socket) {
            [_socket close];
        }
        [self emit:@"disconnected" data:_identifier];
        [self perform:@selector(peer:didDisconnectPeer:) withArgs:@[self,_identifier]];
        _lastServerId = _identifier;
        _identifier = nil;
        
    }
}




-(void)reconnect {
    if (_disconnected && !_destroyed) {
        DDLogDebug(@"Attempting reconnection to server with ID %@", _lastServerId);
        _disconnected = false;
        [self initializeServerConnection];
        [self initialize:_lastServerId];
    } else if (_destroyed) {
        DDLogError(@"This peer cannot reconnect to the server. It has already been destroyed.");
        @throw  [NSError errorWithLocalizedDescription:@"This peer cannot reconnect to the server. It has already been destroyed."];
    } else if (!_disconnected && !_open) {
        // Do nothing. We're still connecting the first time.
        DDLogError(@"In a hurry? We\'re still trying to make the initial connection!");
    } else {
        DDLogError(@"Peer '%@' cannot reconnect because it is not disconnected from the server!",_identifier);
        @throw [NSError errorWithLocalizedDescription:@"Peer '%@' cannot reconnect because it is not disconnected from the server!",_identifier];
    }
};


-(void)listAllPeers:(void (^)(NSArray * array))cb {
    
    DDLogDebug(@"Attermpting to list all peers");
    NSString * protocol = _options.secure ? @"https://" : @"http://";
    NSString * queryString = [NSString stringWithFormat:@"?ts=%f%d",[[NSDate date] timeIntervalSince1970],rand()];
    NSString * url = [NSString stringWithFormat:@"%@%@:%@%@%@/peers%@",protocol, _options.host,_options.port,
                      _options.path, _options.key,queryString];
    
    // If there's no ID we need to wait for one before trying to init socket.
    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error) {
            DDLogError(@"Error retrieving ID %@",[error localizedDescription]);
            
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
                DDLogError(@"It doesn\'t look like you have permission to list peers IDs. %@", helpfulError);
                @throw [NSError errorWithLocalizedDescription:@"It doesn\'t look like you have permission to list peers IDs. %@", helpfulError];
            } else if (resp.statusCode != 200) {
                cb(@[]);
            } else {
                NSError * error;
                NSArray * list = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if(error) {
                    DDLogError(@"Error while listing peers: %@",[error localizedDescription]);
                }
                cb(list);
            }
        }
    }];
    [task resume];
    
}
- (void)applicationWillResignActive:(UIApplication *)application {
    DDLogDebug(@"Application will resign active");
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    DDLogDebug(@"Application did enter background");
    [self destroy];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    DDLogDebug(@"Application will enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DDLogDebug(@"Application did become active");
}

- (void)applicationWillTerminate:(UIApplication *)application {
    DDLogDebug(@"Application will terminate");
    [self destroy];
}
@end
