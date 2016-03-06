//
//  OGPeerObjCTests.m
//  OGPeerObjCTests
//
//  Created by Omar Hussain on 3/2/16.
//  Copyright © 2016 ohgarage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OGPacker.h"
#import "OGUnpacker.h"
@interface OGPeerObjCTests : XCTestCase
@property (nonatomic, strong) OGPacker * packer;
@end

@implementation OGPeerObjCTests

- (void)setUp {
    [super setUp];
    _packer = [[OGPacker alloc] init];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    [_packer pack:@{@"message":@"hellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohello",@"sender":@"omar"}];
    NSData * data  = [_packer getBuffer];
    OGUnpacker * unpacker = [[OGUnpacker alloc] initWithData:data];
    id val = [unpacker unpack];
    XCTAssertNotNil(val,@"Not unpacked");
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
