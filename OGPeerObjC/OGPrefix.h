//
//  OGPrefix.h
//  OGPeerObjectiveC
//
//  Created by Omar Hussain on 2/11/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#ifndef OGPrefix_h
#define OGPrefix_h
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NSError+Extensions.h"

#if DEBUG
static DDLogLevel ddLogLevel = DDLogLevelDebug;
#else
static DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif
#endif /* OGPrefix_h */
