/*	Simple mock ShipEntity for testing OOShipGroup.
*/

#import "OOWeakReference.h"

@class OOShipGroup;


@interface Entity: OOWeakRefObject
{
	OOWeakReference		*_owner;
}

@property (assign /*weakref*/) Entity *owner;

@end


@interface ShipEntity: Entity
{
	NSString			*_name;
	OOShipGroup			*_group;
}

- (id) initWithName:(NSString *)name;

@property (readonly) NSString *name;

@property (retain) OOShipGroup *group;

@end
