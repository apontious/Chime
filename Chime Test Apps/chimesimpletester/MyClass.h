//
//  MyClass.h
//
//  Created by Andrew Pontious on 2/1/14.
//  Released into public domain.
//

@interface MyClass

@property (nonatomic) int myProperty;

- (int)importantNumber;
- (void)setImportantNumber:(int)number;

@end

@interface MyClass (Foo)
@end
