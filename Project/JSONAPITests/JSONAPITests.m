//
//  JSONAPITests.m
//  JSONAPITests
//
//  Created by Josh Holtz on 12/23/13.
//  Copyright (c) 2013 Josh Holtz. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "JSONAPI.h"
#import "JSONAPIResourceDescriptor.h"
#import "JSONAPIErrorResource.h"

#import "CommentResource.h"
#import "PeopleResource.h"
#import "PostResource.h"

@interface JSONAPITests : XCTestCase

@end

@implementation JSONAPITests

- (void)setUp {
    [super setUp];

    [JSONAPIResourceDescriptor addResource:[CommentResource class]];
    [JSONAPIResourceDescriptor addResource:[PeopleResource class]];
    [JSONAPIResourceDescriptor addResource:[PostResource class]];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testMeta {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    XCTAssertNotNil(jsonAPI.meta, @"Meta should not be nil");
    XCTAssertEqualObjects(jsonAPI.meta[@"hehe"], @"hoho", @"Meta's 'hehe' should equal 'hoho'");
}

- (void)testDataPosts {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    XCTAssertNotNil(jsonAPI.resource, @"Resource should not be nil");
    XCTAssertNotNil(jsonAPI.resources, @"Resources should not be nil");
    XCTAssertEqual(jsonAPI.resources.count, 1, @"Resources should contain 1 resource");
    
    PostResource *post = jsonAPI.resource;
    XCTAssert([post isKindOfClass:[PostResource class]], @"Post should be a PostResource");
    XCTAssertEqualObjects(post.ID, @"1", @"Post id should be 1");
    XCTAssertEqualObjects(post.title, @"JSON API paints my bikeshed!", @"Post title should be 'JSON API paints my bikeshed!'");
}

- (void)testIncludedPeopleAndComments {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    XCTAssertNotNil(jsonAPI.includedResources, @"Included resources should not be nil");
    XCTAssertEqual(jsonAPI.includedResources.count, 2, @"Included resources should contain 2 types");
    
}

- (void)testDataPostAuthorAndComments {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    PostResource *post = jsonAPI.resource;
    XCTAssertNotNil(post.author, @"Post's author should not be nil");
    XCTAssertNotNil(post.comments, @"Post's comments should not be nil");
    XCTAssertEqual(post.comments.count, 2, @"Post should contain 2 comments");
}

- (void)testIncludedCommentIsLinked {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    CommentResource *comment = [jsonAPI includedResource:@"5" withType:@"comments"];
    XCTAssertNotNil(comment.author, @"Comment's author should not be nil");
    XCTAssertEqualObjects(comment.author.ID, @"9", @"Comment's author's ID should be 9");
}

- (void)testNoError {
    NSDictionary *json = [self mainExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
 
    XCTAssertFalse([jsonAPI hasErrors], @"JSON API should not have errors");
}

- (void)testError {
    NSDictionary *json = [self errorExampleJSON];
    JSONAPI *jsonAPI = [JSONAPI jsonAPIWithDictionary:json];
    
    XCTAssertTrue([jsonAPI hasErrors], @"JSON API should have errors");
    
    JSONAPIErrorResource *error = jsonAPI.errors.firstObject;
    XCTAssertEqualObjects(error.ID, @"123456", @"Error id should be 123456");
}

- (void)testSerializeSimple {
    PeopleResource *newAuthor = [[PeopleResource alloc] init];
    
    newAuthor.firstName = @"Karl";
    newAuthor.lastName = @"Armstrong";
    
    NSDictionary *json = [newAuthor dictionary];
    XCTAssertEqualObjects(json[@"type"], @"people", @"Did not create person!");
    XCTAssertEqualObjects(json[@"first-name"], @"Karl", @"Wrong first name!");
    XCTAssertNil(json[@"twitter"], @"Wrong Twitter!.");
}

- (void)testSerializeWithFormat {
    PostResource *newPost = [[PostResource alloc] init];
    newPost.title = @"Title";
    newPost.date = [NSDate date];
    
    NSDictionary *json = [newPost dictionary];
    XCTAssertEqualObjects(json[@"type"], @"posts", @"Did not create post!");
    XCTAssertNotNil(json[@"date"], @"Wrong date!");
    XCTAssertTrue([json[@"date"] isKindOfClass:[NSString class]], @"Date should be string!.");
}

- (void)testSerializeComplex {
    PeopleResource *newAuthor = [[PeopleResource alloc] init];
    
    newAuthor.ID = [NSUUID UUID];
    newAuthor.firstName = @"Karl";
    newAuthor.lastName = @"Armstrong";
    
    CommentResource *newComment = [[CommentResource alloc] init];
    newComment.ID = [NSUUID UUID];
    newComment.author = newAuthor;
    newComment.text = @"First!";
    
    PostResource *newPost = [[PostResource alloc] init];
    newPost.title = @"Title";
    newPost.author = newAuthor;
    newPost.date = [NSDate date];
    newPost.comments = [[NSArray alloc] initWithObjects:newComment, nil];
    
    NSDictionary *json = [newPost dictionary];
    XCTAssertEqualObjects(json[@"type"], @"posts", @"Did not create Post!");
    XCTAssertNotNil(json[@"links"], @"Did not create links!");
    XCTAssertNotNil(json[@"links"][@"author"], @"Did not create links!");
    XCTAssertNotNil(json[@"links"][@"author"][@"linkage"], @"Did not create links!");
    XCTAssertEqualObjects(json[@"links"][@"author"][@"linkage"][@"id"], newAuthor.ID, @"Wrong link ID!.");
    XCTAssertNil(json[@"links"][@"author"][@"first-name"], @"Bad link!");

    XCTAssertNotNil(json[@"links"][@"comments"], @"Did not create links!");
    XCTAssertTrue([json[@"links"][@"comments"] isKindOfClass:[NSArray class]], @"Comments should be array!.");
    XCTAssertEqual([json[@"links"][@"comments"] count], 1, @"Comments should have 1 element!.");
}

- (void)testCreate {
  PeopleResource *newAuthor = [[PeopleResource alloc] init];
  
  newAuthor.firstName = @"Karl";
  newAuthor.lastName = @"Armstrong";
  
  JSONAPI *jsonAPI = [JSONAPI jsonAPIWithResource:newAuthor];
  XCTAssertEqualObjects([jsonAPI dictionary][@"data"][@"type"], @"people", @"Did not create person!");
}

#pragma mark - Private

- (NSDictionary*)mainExampleJSON {
    return [self jsonFor:@"main_example" ofType:@"json"];
}

- (NSDictionary*)errorExampleJSON {
    return [self jsonFor:@"error_example" ofType:@"json"];
}

- (NSDictionary*)jsonFor:(NSString*)resource ofType:(NSString*)type {
    NSString *path = [[NSBundle mainBundle] pathForResource:resource ofType:type];
    NSString *jsonStr = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    return [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

@end
