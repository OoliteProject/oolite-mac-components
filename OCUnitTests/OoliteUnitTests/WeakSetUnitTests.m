/*

weakSetUnitTests.m

Unit tests for OOWeakSet.


Written by Jens Ayton in 2012 for Oolite.
This code is hereby placed in the public domain.

*/

#import "weaksetUnitTests.h"
#import "OOWeakSet.h"
#import "OOWeakTestObject.h"


@implementation weaksetUnitTests

- (void) tearDown
{
	/*	Workaround for a stupid bug in ocunit where it sometimes exits before
		it finishes logging results.
	*/
	[super tearDown];
	[NSThread sleepForTimeInterval:0.5];
}

- (void) testAddAndCount
{
    OOWeakTestObject *three = [OOWeakTestObject objectWithValue:3];
    OOWeakTestObject *seven = [OOWeakTestObject objectWithValue:7];
	
	OOWeakSet *ws = [OOWeakSet set];
	XCTAssertNotNil(ws, @"Creating a weak set should produce a set.");
	
	XCTAssertEqual(ws.count, (NSUInteger)0, @"A newly created weak set should be empty.");
	
	[ws addObject:three];
	[ws addObject:seven];
	
	XCTAssertEqual(ws.count, (NSUInteger)2, @"After adding two distinct objects, weak set's count should be 2.");
	
	[ws addObject:three];
	[ws addObject:three];
	
	XCTAssertEqual(ws.count, (NSUInteger)2, @"Adding duplicate objects should not increase weak set's count.");
}


- (void) testContainsObject
{
    OOWeakTestObject *three = [OOWeakTestObject objectWithValue:3];
    OOWeakTestObject *seven = [OOWeakTestObject objectWithValue:7];
	OOWeakSet *ws = [OOWeakSet set];
	
	[ws addObject:three];
	
	XCTAssertTrue([ws containsObject:three], @"Weak set should contain object that was added.");
	XCTAssertFalse([ws containsObject:seven], @"Weak set should not contain object that wasn't added.");
}


- (void) testRemoveObject
{
    OOWeakTestObject *three = [OOWeakTestObject objectWithValue:3];
    OOWeakTestObject *seven = [OOWeakTestObject objectWithValue:7];
	OOWeakSet *ws = [OOWeakSet set];
	
	[ws addObject:three];
	[ws addObject:seven];
	
	XCTAssertEqual(ws.count, (NSUInteger)2, @"After adding two distinct objects, weak set's count should be 2.");
	
	XCTAssertTrue([ws containsObject:three], @"Weak set should contain object that was added.");
	XCTAssertTrue([ws containsObject:seven], @"Weak set should contain object that was added.");
	
	[ws removeObject:three];
	
	XCTAssertEqual(ws.count, (NSUInteger)1, @"After adding two distinct objects and removing one, weak set's count should be 1.");
	
	XCTAssertFalse([ws containsObject:three], @"Weak set should not contain object that was removed.");
	XCTAssertTrue([ws containsObject:seven], @"Weak set should contain object that was not removed.");
}


- (void) testEquality
{
    OOWeakTestObject *three = [OOWeakTestObject objectWithValue:3];
    OOWeakTestObject *seven = [OOWeakTestObject objectWithValue:7];
	OOWeakSet *ws1 = [OOWeakSet set];
	OOWeakSet *ws2 = [OOWeakSet set];
	
	XCTAssertTrue([ws1 isEqual:ws2], @"Two empty weak sets should be equal.");
	
	[ws1 addObject:three];
	[ws2 addObject:seven];
	XCTAssertFalse([ws1 isEqual:ws2], @"Two weak sets containing different objects should not be equal.");
	
	[ws2 addObject:three];
	[ws1 addObject:seven];
	
	XCTAssertTrue([ws1 isEqual:ws2], @"Two weak sets containing the same objects should be equal.");
}


- (void) testWeakness
{
    OOWeakTestObject *three = [OOWeakTestObject objectWithValue:3];
	OOWeakSet *ws = [OOWeakSet set];
	
	@autoreleasepool
	{
		OOWeakTestObject *seven = [OOWeakTestObject objectWithValue:7];
		
		[ws addObject:three];
		[ws addObject:seven];
		
		XCTAssertEqual(ws.count, (NSUInteger)2, @"After adding two distinct objects, weak set's count should be 2.");
	}
	
	XCTAssertEqual(ws.count, (NSUInteger)1, @"After one object's lifetime expired, weak set's count should be 1.");
	XCTAssertTrue([ws containsObject:three], @"Weak set should contain object which has not expired.");
}


- (void) testPerformSelector
{
    OOWeakTestObject *three = [OOWeakTestObject objectWithValue:3];
    OOWeakTestObject *seven = [OOWeakTestObject objectWithValue:7];
    OOWeakTestObject *nine = [OOWeakTestObject objectWithValue:9];
	OOWeakSet *ws = [OOWeakSet set];
	
	[ws addObject:three];
	[ws addObject:seven];
	
	NSMutableSet *set = [NSMutableSet set];
	
	[ws makeObjectsPerformSelector:@selector(addSelfToSet:) withObject:set];
	
	XCTAssertEqual(set.count, ws.count, @"After after having objects from weak set add themselves to a strong set, the two sets' counts should match.");
	XCTAssertTrue([set containsObject:three], @"Strong set should contain object copied from weak set.");
	XCTAssertTrue([set containsObject:seven], @"Strong set should contain object copied from weak set.");
	
	[ws addObject:nine];
	
	XCTAssertFalse([set containsObject:nine], @"Strong set should not contain object not copied from weak set.");
}

@end
