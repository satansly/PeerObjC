//
//  OGConnection.m
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/10/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGConnection.h"
#import "OGUtil.h"
#import "OGNegotiator.h"

@implementation OGConnection
-(instancetype)init __attribute__((unavailable("Init method is not a supported for OGConnection. Use OGConnection subclass"))){
    self = [super init]; __weak typeof(self) weakSelf = self;
    [self on:@"error" callback:^(NSError * error) {
        [weakSelf perform:@selector(connection:onError:) withArgs:@[weakSelf,error]];
    }];
    [self on:@"open" callback:^(OGConnection * conn) {
        [weakSelf perform:@selector(connectionOnOpen:) withArgs:@[weakSelf]];
    }];
    [self on:@"close" notify:^{
        [weakSelf perform:@selector(connectionOnClose:) withArgs:@[weakSelf]];
    }];
    return self;
}
-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider __attribute__((unavailable("Init method is not a supported for OGConnection. Use OGConnection subclass"))){
    return nil;
}
-(instancetype)initWithPeer:(NSString *)peer provider:(OGPeer *)provider options:(id<OGConnectionOptions>)options __attribute__((unavailable("Init method is not a supported for OGConnection. Use OGConnection subclass"))){
    return nil;
}
-(void)initialize __attribute__((unavailable("initializer is not a supported for OGConnection. Use OGConnection subclass"))){
    
}
-(void)handleMessage:(OGMessage *)message __attribute__((unavailable("handleMessage is not a supported for OGConnection. Use OGConnection subclass"))){
    
}

+(NSString *)identifierPrefix __attribute__((unavailable("identifierPrefix is not a supported for OGConnection. Use OGConnection subclass"))){
    return nil;
}
-(NSString *)typeAsString {
    return [[OGUtil util] stringFromConnectionType:_type];
}
-(NSString *)serializationAsString {
    return [[OGUtil util] stringFromSerialization:_serialization];
}
/** Allows user to close connection. */
-(void)close {
    if (!self.open) {
        return;
    }
    _open = false;
    [_negotiator cleanup:self];
    [self emit:@"close"];
    
}
@end
