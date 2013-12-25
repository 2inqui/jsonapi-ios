//
//  PostResource.m
//  JSONAPI
//
//  Created by Josh Holtz on 12/24/13.
//  Copyright (c) 2013 Josh Holtz. All rights reserved.
//

#import "PostResource.h"

@implementation PostResource

- (PeopleResource *)author {
    return [self linkedResourceForKey:@"author"];
}

- (NSArray *)comments {
    return [self linkedResourceForKey:@"comments"];
}

- (NSString *)name {
    return [self objectForKey:@"name"];
}

@end
