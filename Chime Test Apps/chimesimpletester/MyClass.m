//
//  MyClass.m
//
//  Created by Andrew Pontious on 2/1/14.
//  Released into public domain.
//

#import "MyClass.h"

@protocol Foo
@end

@interface MyClass () <Foo>

@property int privateProperty;

@end

@interface MyClass ()
@end

@implementation MyClass

- (int)importantNumber {
    return self.myProperty;
}
- (void)setImportantNumber:(int)number {
    self.myProperty = number;
}

@end

@implementation MyClass (Foo)
@end
