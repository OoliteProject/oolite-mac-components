#import <XCTest/XCTest.h>

#import "OOPriorityQueue.h"

_Static_assert(__has_feature(objc_arc), "This file requires ARC");


@interface OOPriorityQueueTest : XCTestCase
@end


@interface OOPriorityQueueTestObject: NSObject

- (instancetype)initWithPayload:(NSUInteger)payload;

@property (readonly) NSUInteger payload;

- (NSComparisonResult)customCompare:(OOPriorityQueueTestObject *)other;

@end


@implementation OOPriorityQueueTest

- (void)testAddAndRetrieveObject
{
	OOPriorityQueue *queue = [OOPriorityQueue new];
	XCTAssertEqual(queue.count, 0);

	id test = @"foo";
	[queue addObject:test];
	XCTAssertEqual(queue.count, 1);

	id fetched = [queue nextObject];
	XCTAssertEqual(queue.count, 0);
	XCTAssertEqualObjects(test, fetched);
}

- (void)testAddAndPeekObject
{
	OOPriorityQueue *queue = [OOPriorityQueue new];
	XCTAssertEqual(queue.count, 0);

	id test = @"foo";
	[queue addObject:test];
	XCTAssertEqual(queue.count, 1);

	id fetched = [queue peekAtNextObject];
	XCTAssertEqual(queue.count, 1);
	XCTAssertEqualObjects(test, fetched);
}

- (void)testNonComparable
{
	OOPriorityQueue *queue = [OOPriorityQueue new];
	id test = [[OOPriorityQueueTestObject alloc] initWithPayload:1];
	XCTAssertThrows([queue addObject:test]);
}

- (void)testCustomComparable
{
	OOPriorityQueue *queue = [OOPriorityQueue queueWithComparator:@selector(customCompare:)];
	id test = [[OOPriorityQueueTestObject alloc] initWithPayload:1];
	XCTAssertNoThrow([queue addObject:test]);
}

- (void)testCustomComparison
{
	OOPriorityQueue *queue = [OOPriorityQueue queueWithComparator:@selector(customCompare:)];
	id test1 = [[OOPriorityQueueTestObject alloc] initWithPayload:1];
	id test2 = [[OOPriorityQueueTestObject alloc] initWithPayload:2];
	id test3 = [[OOPriorityQueueTestObject alloc] initWithPayload:3];

	[queue addObject:test2];
	[queue addObject:test3];
	[queue addObject:test1];

	XCTAssertEqual([[queue nextObject] payload], 1);
	XCTAssertEqual([[queue nextObject] payload], 2);
	XCTAssertEqual([[queue nextObject] payload], 3);

	XCTAssertEqual(queue.count, 0);
}

- (void)testRemoveObject
{
	OOPriorityQueue *queue = [OOPriorityQueue queueWithComparator:@selector(customCompare:)];
	id test1 = [[OOPriorityQueueTestObject alloc] initWithPayload:1];
	id test2 = [[OOPriorityQueueTestObject alloc] initWithPayload:2];
	id test3 = [[OOPriorityQueueTestObject alloc] initWithPayload:3];

	[queue addObject:test2];
	[queue addObject:test3];
	[queue addObject:test1];
	[queue removeObject:test2];

	XCTAssertEqual([[queue nextObject] payload], 1);
	XCTAssertEqual([[queue nextObject] payload], 3);

	XCTAssertEqual(queue.count, 0);
}

- (void)testRemoveSpecificObject
{
	OOPriorityQueue *queue = [OOPriorityQueue queueWithComparator:@selector(customCompare:)];
	// Note: all equal, but distinct.
	id test1 = [[OOPriorityQueueTestObject alloc] initWithPayload:1];
	id test2 = [[OOPriorityQueueTestObject alloc] initWithPayload:1];
	id test3 = [[OOPriorityQueueTestObject alloc] initWithPayload:1];

	[queue addObject:test2];
	[queue addObject:test3];
	[queue addObject:test1];
	[queue removeObject:test3];

	XCTAssertNotEqual([queue nextObject], test3);
	XCTAssertNotEqual([queue nextObject], test3);

	XCTAssertEqual(queue.count, 0);
}

- (void)testEquality
{
	// Note: permuations of the same objects.
	NSArray *array1 = [NSArray arrayWithObjects: @"dog", @"cat", @"apple", @"zebra", @"spanner", @"cat", nil];
	NSArray *array2 = [NSArray arrayWithObjects: @"apple", @"cat", @"dog", @"zebra", @"cat", @"spanner", nil];
	OOPriorityQueue	*q1 = [[OOPriorityQueue alloc] init];
	OOPriorityQueue	*q2 = [[OOPriorityQueue alloc] init];

	[q1 addObjects:array1];
	[q2 addObjects:array2];
	XCTAssertEqualObjects(q1, q2);

	[q2 addObject:@"snake"];
	XCTAssertNotEqualObjects(q1, q2);

	[q2 removeObject:@"snake"];
	XCTAssertEqualObjects(q1, q2);
}

- (void)testSortedNumbersWithNextObject
{
	srandom(424242);
	NSUInteger count = 50;
	OOPriorityQueue *queue = [OOPriorityQueue new];

	for (NSUInteger i = 0; i < count; i++) {
		[queue addObject:@(random() % 100)];
	}

	XCTAssertEqual(queue.count, count);

	NSMutableArray *items = [NSMutableArray new];
	for (;;) {
		id next = [queue nextObject];
		if (next == nil)  break;
		[items addObject:next];
	}

	NSArray *sorted = [items sortedArrayUsingSelector:@selector(compare:)];
	XCTAssertNotEqual(items, sorted);		// distinct objects...
	XCTAssertEqualObjects(items, sorted);	// ...same contents.
	XCTAssertEqual(sorted.count, count);
}

- (void)testSortedNumbersWithObjectEnumerator
{
	srandom(424243);
	NSUInteger count = 50;
	OOPriorityQueue *queue = [OOPriorityQueue new];

	for (NSUInteger i = 0; i < count; i++) {
		[queue addObject:@(random() % 100)];
	}

	XCTAssertEqual(queue.count, count);

	NSMutableArray *items = [NSMutableArray new];
	NSEnumerator *enumerator = [queue objectEnumerator];
	for (id next in enumerator) {
		[items addObject:next];
	}

	NSArray *sorted = [items sortedArrayUsingSelector:@selector(compare:)];
	XCTAssertNotEqual(items, sorted);		// distinct objects...
	XCTAssertEqualObjects(items, sorted);	// ...same contents.
	XCTAssertEqual(sorted.count, count);
}

- (void)testSortedNumbersWithSortedObjects
{
	srandom(424244);
	NSUInteger count = 50;
	OOPriorityQueue *queue = [OOPriorityQueue new];

	for (NSUInteger i = 0; i < count; i++) {
		[queue addObject:@(random() % 100)];
	}

	XCTAssertEqual(queue.count, count);

	NSArray *items = [queue sortedObjects];

	NSArray *sorted = [items sortedArrayUsingSelector:@selector(compare:)];
	XCTAssertNotEqual(items, sorted);		// distinct objects...
	XCTAssertEqualObjects(items, sorted);	// ...same contents.
	XCTAssertEqual(sorted.count, count);
}

@end


@implementation OOPriorityQueueTestObject: NSObject

- (instancetype)initWithPayload:(NSUInteger)payload
{
	if ((self = [super init])) {
		_payload = payload;
	}
	return self;
}

- (NSComparisonResult)customCompare:(OOPriorityQueueTestObject *)other
{
	NSParameterAssert([other isKindOfClass:[OOPriorityQueueTestObject class]]);

	if (self.payload < other.payload) {
		return NSOrderedAscending;
	} else if (other.payload < self.payload) {
		return NSOrderedDescending;
	} else {
		return NSOrderedSame;
	}
}

- (BOOL)isEqual:(id)object
{
	if ([object isKindOfClass:[OOPriorityQueueTestObject class]]) {
		return [self customCompare:object] == NSOrderedSame;
	} else {
		return NO;
	}
}

- (NSUInteger)hash
{
	return self.payload;
}

@end
