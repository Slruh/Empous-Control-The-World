#import "Extras.h"

CGLine CGLineMake(CGPoint point1, CGPoint point2)
{
    CGLine line;
    line.point1.x = point1.x;
    line.point1.y = point1.y;
    line.point2.x = point2.x;
    line.point2.y = point2.y;
    return line;
}