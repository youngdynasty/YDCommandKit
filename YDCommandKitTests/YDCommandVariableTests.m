//
//  YDCommandVariableTests.m
//  emporter-cli-tests
//
//  Created by Mikey on 21/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YDCommandVariable.h"

@interface YDCommandVariableTests : XCTestCase
@end


@implementation YDCommandVariableTests

#pragma mark - Types

- (void)testBooleanImplicit {
    BOOL v;
    NSArray *variables = @[[YDCommandVariable boolean:&v withName:@"--test" usage:@""]];
    NSArray *expectedExtraArgs = @[@"-", @"neato2"];
    NSArray *args = [@[@"--test"] arrayByAddingObjectsFromArray:expectedExtraArgs];
    NSArray *extraArgs = nil;
    NSError *error = nil;

    XCTAssertTrue([YDCommandVariableScanner scanVariables:variables arguments:args extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqual(v, YES);
    XCTAssertEqualObjects(extraArgs, expectedExtraArgs);
}

- (void)testBooleanExplicit {
    BOOL v;
    NSArray *variables = @[[YDCommandVariable boolean:&v withName:@"--test" usage:@""]];
    NSArray *expectedExtraArgs = @[@"-", @"neato2"];
    NSArray *extraArgs = nil;
    NSError *error = nil;

    XCTAssertTrue([YDCommandVariableScanner scanVariables:variables arguments:[@[@"--test=1"] arrayByAddingObjectsFromArray:expectedExtraArgs] extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqual(v, YES);
    XCTAssertEqualObjects(extraArgs, expectedExtraArgs);

    XCTAssertTrue([YDCommandVariableScanner scanVariables:variables arguments:[@[@"--test=0"] arrayByAddingObjectsFromArray:expectedExtraArgs] extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqual(v, NO);
    XCTAssertEqualObjects(extraArgs, expectedExtraArgs);
}

- (void)testInteger {
    NSInteger v;
    NSArray *variables = @[[YDCommandVariable integer:&v withName:@"--test" usage:@""]];
    NSArray *expectedExtraArgs = @[@"-", @"neato2"];
    NSInteger expectedValue = 1234;
    NSArray *args = [@[@"--test", [@(expectedValue) stringValue]] arrayByAddingObjectsFromArray:expectedExtraArgs];
    NSArray *extraArgs = nil;
    NSError *error = nil;
    
    XCTAssertTrue([YDCommandVariableScanner scanVariables:variables arguments:args extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqual(v, expectedValue);
    XCTAssertEqualObjects(extraArgs, expectedExtraArgs);

    v = 0;
    NSArray *altArgs = @[[NSString stringWithFormat:@"--test=%@", @(expectedValue)]];
    
    XCTAssertTrue([YDCommandVariableScanner scanVariables:variables arguments:altArgs extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqual(v, expectedValue);
    XCTAssertEqualObjects(extraArgs, @[]);
}

- (void)testString {
    NSString *v = nil;
    NSArray *variables = @[[YDCommandVariable string:&v withName:@"--test" usage:@""]];
    NSString *expectedValue = @"wow";
    NSArray *expectedExtraArgs = @[@"neato1", @"neato2"];
    NSArray *args = [@[@"--test", expectedValue] arrayByAddingObjectsFromArray:expectedExtraArgs];
    NSArray *extraArgs = nil;
    NSError *error = nil;

    XCTAssertTrue([YDCommandVariableScanner scanVariables:variables arguments:args extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqualObjects(v, expectedValue);
    XCTAssertEqualObjects(extraArgs, expectedExtraArgs);
    
    v = nil;
    NSArray *altArgs = @[[NSString stringWithFormat:@"--test=%@", expectedValue]];
    
    XCTAssertTrue([YDCommandVariableScanner scanVariables:variables arguments:altArgs extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqualObjects(v, expectedValue);
    XCTAssertEqualObjects(extraArgs, @[]);
}

- (void)testCombination {
    NSString *strVal = nil;
    NSInteger intVal = 0;
    BOOL boolVal = NO;
    
    NSArray *variables = @[
                           [YDCommandVariable string:&strVal withName:@"--string" usage:@""],
                           [YDCommandVariable integer:&intVal withName:@"--integer" usage:@""],
                           [YDCommandVariable boolean:&boolVal withName:@"--bool" usage:@""],
                           ];
    
    NSArray *expectedExtraArgs = @[@"neato1", @"neato2"];
    NSArray *args = [@[@"--string=str", @"--integer", @"4321", @"--bool=0"] arrayByAddingObjectsFromArray:expectedExtraArgs];
    NSArray *extraArgs = nil;
    NSError *error = nil;
    
    XCTAssertTrue([YDCommandVariableScanner scanVariables:variables arguments:args extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqual(intVal, 4321);
    XCTAssertEqual(boolVal, NO);
    XCTAssertEqualObjects(strVal, @"str");
    XCTAssertEqualObjects(extraArgs, expectedExtraArgs);
}

#pragma mark - Delimiters

- (void)testExplicitDelimiter {
    NSArray *expectedExtraArgs = @[@"--neato1", @"neato2"];
    NSArray *args = [@[@"--"] arrayByAddingObjectsFromArray:expectedExtraArgs];
    NSArray *extraArgs = nil;
    NSError *error = nil;
    
    XCTAssertTrue([YDCommandVariableScanner scanVariables:@[] arguments:args extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqualObjects(extraArgs, expectedExtraArgs);
}

- (void)testImplicitDelimiter {
    NSArray *expectedExtraArgs = @[@"-", @"--neato1"];
    NSArray *extraArgs = nil;
    NSError *error = nil;
    
    XCTAssertTrue([YDCommandVariableScanner scanVariables:@[] arguments:expectedExtraArgs extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqualObjects(extraArgs, expectedExtraArgs);
}

#pragma mark -

- (void)testAlias {
    NSInteger v;
    NSArray *variables = @[[[YDCommandVariable integer:&v withName:@"--test" usage:@""] variableWithAlias:@"-t"]];
    NSArray *expectedExtraArgs = @[@"-", @"neato2"];
    NSInteger expectedValue = 1234;
    NSArray *args = [@[@"-t", [@(expectedValue) stringValue]] arrayByAddingObjectsFromArray:expectedExtraArgs];
    NSArray *extraArgs = nil;
    NSError *error = nil;
    
    XCTAssertTrue([YDCommandVariableScanner scanVariables:variables arguments:args extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertEqual(v, expectedValue);
    XCTAssertEqualObjects(extraArgs, expectedExtraArgs);
}

#pragma mark - Errors

- (void)testUnrecognizedArgument {
    NSArray *args = @[@"--neato1"];
    NSArray *extraArgs = nil;
    NSError *error = nil;
    
    XCTAssertFalse([YDCommandVariableScanner scanVariables:@[] arguments:args extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertNil(extraArgs);
    XCTAssertEqualObjects(error.domain, YDCommandErrorDomain);
    XCTAssertEqual(error.code, YDCommandErrorCodeUnknownVariable);
    XCTAssertNotNil(error.userInfo);
    XCTAssertEqualObjects(error.userInfo[YDCommandVariableNameKey], [args firstObject]);
}

- (void)testBadInteger {
    NSInteger v;
    NSArray *variables = @[[YDCommandVariable integer:&v withName:@"--test" usage:@""]];
    NSArray *args = @[@"--test", @"oops"];
    NSArray *extraArgs = nil;
    NSError *error = nil;
    
    XCTAssertFalse([YDCommandVariableScanner scanVariables:variables arguments:args extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertNil(extraArgs);
    XCTAssertEqualObjects(error.domain, YDCommandErrorDomain);
    XCTAssertEqual(error.code, YDCommandErrorCodeParseError);
    XCTAssertNotNil(error.userInfo);
    XCTAssertEqualObjects(error.userInfo[YDCommandVariableNameKey], [args firstObject]);
    XCTAssertEqualObjects(error.userInfo[YDCommandVariableValueKey], [args lastObject]);
}

- (void)testMissingValueTrailing {
    NSInteger v = 0;
    NSArray *variables = @[[YDCommandVariable integer:&v withName:@"--test" usage:@""]];
    NSArray *args = @[@"--test"];
    NSArray *extraArgs = nil;
    NSError *error = nil;
    
    XCTAssertFalse([YDCommandVariableScanner scanVariables:variables arguments:args extraArguments:&extraArgs error:&error], "%@", error);
    XCTAssertNil(extraArgs);
    XCTAssertEqualObjects(error.domain, YDCommandErrorDomain);
    XCTAssertEqual(error.code, YDCommandErrorCodeParseError);
    XCTAssertNotNil(error.userInfo);
    XCTAssertEqualObjects(error.userInfo[YDCommandVariableNameKey], [args firstObject]);
    XCTAssertNil(error.userInfo[YDCommandVariableValueKey]);
}

@end
