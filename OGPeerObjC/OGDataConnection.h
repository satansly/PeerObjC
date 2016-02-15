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

/**
 *  @brief Options associated with a data connection object at the time of initalizing
 */
@interface OGDataConnectionOptions : NSObject<OGConnectionOptions>
/**
 *  @brief <#Description#>
 */
@property (nonatomic, strong) NSString * label;
@property (nonatomic, assign) OGSerialization serialization;
@property (nonatomic, assign) BOOL reliable;
@end


@interface OGDataConnection : OGConnection

@property (nonatomic, strong) RTCDataChannel * dataChannel;
@property (nonatomic, assign) BOOL reliable;
@property (nonatomic, strong) NSNumber * bufferSize;

- (void)initialize:(RTCDataChannel *)dataChannel;
- (void)send:(id)data;
@end
