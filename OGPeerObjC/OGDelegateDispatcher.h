//
//  OGDelegateDispatcher.h
//  OGPeerObjC
//
//  Created by Omar Hussain on 2/18/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 *  @brief Utility class to help with message dispatching
 */
@interface OGDelegateDispatcher : NSObject
/**
 *  @brief weakly referenced delegate objects
 */
@property (nonatomic, strong, readonly) NSMutableArray * delegates;
/**
 *  @brief Adds a pointer to delegate to the delegates
 *
 *  @param delegate Delegate object capable of receiving messages
 */
-(void)addDelegate:(id<NSObject>)delegate;
/**
 *  @brief Removes a pointer to delegate from the delegates
 *
 *  @param delegate Delegate object capable of receiving messages
 */
-(void)removeDelegate:(id<NSObject>)delegate;
/**
 *  @brief Performs the provided selector with provided arguments
 *
 *  @param selector Selector to be performed
 *  @param args     Arguments array in order of selector arguments
 */
-(void)perform:(SEL)selector withArgs:(NSArray * )args;
@end
