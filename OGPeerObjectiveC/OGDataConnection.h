//
//  OGDataConnection.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/9/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGCommon.h"
#import "OGConnection.h"
#import "RTCDataChannel.h"
#import "RTCPeerConnection.h"


@class OGPeer;
@class OGDataConnection;

@protocol OGDataConnectionDelegate<NSObject>
- (void)connection:(OGDataConnection *)connection onData:(id)data;
- (void)connectionOnOpen:(OGDataConnection *)connection;
- (void)connectionOnClose:(OGDataConnection *)connection;
- (void)connection:(OGDataConnection *)connection onError:(NSError *)error;
@end

@interface OGDataConnectionOptions : OGConnectionOptions
@property (nonatomic, strong) NSString * label;
@property (nonatomic, assign) OGSerialization serialization;
@property (nonatomic, assign) BOOL reliable;
@end


@interface OGDataConnection : OGConnection

@property (nonatomic, strong) RTCDataChannel * dataChannel;
@property (nonatomic, assign) BOOL open;
@property (nonatomic, assign) BOOL reliable;
@property (nonatomic, strong) NSNumber * bufferSize;

- (instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider options:(OGDataConnectionOptions *)options;
- (instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider;
- (void)initialize:(RTCDataChannel *)dataChannel;
- (void)send:(id)data;
- (void)close;
@end
