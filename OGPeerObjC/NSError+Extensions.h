//
//  NSError+Extensions.h
//  OGPeerObjC
//
//  Created by Omar Hussain on 2/14/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Extensions)
+(NSError *)errorWithLocalizedDescription:(NSString *)str, ...;
@end
