//
//  NSObject+ThrowingKeyValueObserving.h
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (ThrowingKeyValueObserving)

- (void)throwingRemoveObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
- (void)throwingRemoveObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context;

@end
