//
//  NSObject+ThrowingKeyValueObserving.m
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//

#import "NSObject+ThrowingKeyValueObserving.h"


@implementation NSObject (ThrowingKeyValueObserving)

- (void)throwingRemoveObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    @try {
        [self removeObserver:observer forKeyPath:keyPath];
    }
    @catch (NSException *exception) {
        return;
    }
}


- (void)throwingRemoveObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context
{
    @try {
        [self removeObserver:observer forKeyPath:keyPath context:context];
    }
    @catch (NSException *exception) {
        return;
    }
}

@end
