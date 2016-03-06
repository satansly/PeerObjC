//
//  OGDelegateDispatcher.m
//  OGPeerObjC
//
//  Created by Omar Hussain on 2/18/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import "OGDelegateDispatcher.h"
@interface OGDelegateDispatcher ()
@property (nonatomic, strong) NSMutableArray * delegates;
@end
@implementation OGDelegateDispatcher
-(instancetype)init {
    self = [super init];
    self.delegates = [NSMutableArray array];
    return self;
}
-(void)addDelegate:(NSObject *)delegate {
    BOOL found = NO;
    for(NSValue * delegateValue in _delegates) {
        id<NSObject> _delegate = [delegateValue pointerValue];
        if(delegate == _delegate) {
            found = YES;
            break;
        }
    }
    if(!found)
        [_delegates addObject:[NSValue valueWithNonretainedObject:delegate]];
}
-(void)removeDelegate:(NSObject *)delegate {
    NSValue * removeDelegate;
    for(NSValue * delegateValue in _delegates) {
        id<NSObject> _delegate = [delegateValue pointerValue];
        if(delegate == _delegate) {
            removeDelegate = delegateValue;
        }
    }
    [_delegates removeObject:removeDelegate];
}
-(void)perform:(SEL)selector withArgs:(NSArray * )args {
    for(NSValue * delegateValue in self.delegates) {
        if(delegateValue){
        NSObject * delegate = [delegateValue pointerValue];
        if([delegate respondsToSelector:selector]) {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:selector]];
            [inv setSelector:selector];
            [inv setTarget:delegate];
            int index = 2;
            for(__unsafe_unretained id arg in args) {
                [inv setArgument:&arg atIndex:index]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
                index++;
            }
            [inv invoke];
            args = nil;
        }
        }
    }
}
@end
