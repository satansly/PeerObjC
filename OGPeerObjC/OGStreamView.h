//
//  OGStreamView.h
//  Pods
//
//  Created by Omar Hussain on 2/13/16.
//
//

#import <UIKit/UIKit.h>

@class RTCMediaStream;



@interface OGStreamView : UIView
/**
 *  @brief RTCMediaStream object used to render the the video
 */
@property(nonatomic, strong) RTCMediaStream* stream;

/**
 *  @brief Initializes and returns a ready to be displayed stream view
 *
 *  @param stream RTCMediaStream object to populate the view
 *
 *  @return Instance of OGStreamView ready to be displayed in view hierarchy
 */
-(instancetype)initWithStream:(RTCMediaStream *)stream;
/**
 *  @brief Resets renderers and views
 */
-(void)resetSession;
@end
