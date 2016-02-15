//
//  NSError+Extensions.m
//  OGPeerObjC
//
//  Created by Omar Hussain on 2/14/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "NSError+Extensions.h"

@implementation NSError (Extensions)
+(NSError *)errorWithLocalizedDescription:(NSString *)str, ...{
    
    va_list args;
    va_start(args, str);
    NSError * error = [NSError errorWithDomain:@"PeerJS" code:1001 userInfo:@{NSLocalizedDescriptionKey:[[NSString alloc] initWithFormat:str arguments:args]}];
    va_end(args);
    return error;
}
@end
