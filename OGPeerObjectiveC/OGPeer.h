//
//  OGPeer.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
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

@class OGPeer;
@class OGPeerConfig;
@class OGICEServer;
@class OGDataConnection;
@class OGMediaConnection;
@class OGMediaConnectionOptions;
@class OGDataConnectionOptions;
@class OGConnection;

typedef void (^OnOpenBlock)();

@protocol OGPeerDelegate<NSObject>
@optional
- (void)peer:(OGPeer *)peer onOpen:(NSString *)Id;
- (void)peer:(OGPeer *)peer onCall:(OGMediaConnection *)connection;
- (void)peer:(OGPeer *)peer onConnection:(OGDataConnection *)connection;
- (void)peerOnDisconnected:(OGPeer *)peer;
- (void)peerOnClose:(OGPeer *)peer;
- (void)peer:(OGPeer *)peer onError:(NSError *)error;
@end

@interface OGPeerOptions : NSObject
@property (nonatomic, strong) NSString * key;
@property (nonatomic, strong) NSString * host;
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSNumber * port;
@property (nonatomic, assign) BOOL secure;
@property (nonatomic, strong) OGPeerConfig * config;
@end

@interface OGPeerConfig : NSObject
@property (nonatomic, strong) NSArray<RTCICEServer *> * iceServers;
+(OGPeerConfig *)defaultConfig;
+(RTCMediaConstraints *)defaultConstraints;
@end


@interface OGPeer : NSObject

@property (nonatomic, strong) NSString * identifier;
@property (nonatomic, strong) NSMutableDictionary * connections;
@property (nonatomic, strong) OGPeerOptions * options;
@property (nonatomic, strong) SRWebSocket * socket;
@property (nonatomic, strong) RTCMediaConstraints * constraints;
@property (nonatomic, assign) BOOL disconnected;
@property (nonatomic, assign) BOOL destroyed;
@property (nonatomic, assign) BOOL open;


-(instancetype)initWithId:(NSString *)identifier options:(OGPeerOptions *)options;

-(OGDataConnection *)connectToId:(NSString *)identifier options:(OGDataConnectionOptions *)options;

-(OGMediaConnection *)callToId:(NSString *)identifier stream:(OGStreamType)stream options:(OGMediaConnectionOptions *)options;

-(OGConnection *)getConnection:(NSString *)peerId identifier:(NSString *)connectionId;

-(NSArray *)getMessages:(NSString *)peer;
-(void)disableVideo;
-(void)disableAudio;

-(void)enableVideo;
-(void)enableAudio;


-(void)addListener:(id<OGPeerDelegate>)delegate;
-(void)removeListener:(id<OGPeerDelegate>)delegate;

-(void)disconnect;
-(void)reconnect;
-(void)destroy;


@end

