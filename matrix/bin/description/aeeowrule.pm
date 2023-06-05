#!/usr/bin/perl

# Arrow Rule

# In between two subscripts, the arrow is optional.

# Instead of $a[1]->[2], we can write $a[1][2]; it 
# means the same thing. Instead of $a[0]->[1] = 23, 
# we can write $a[0][1] = 23; it means the same thing.

# Now it really looks like two-dimensional arrays!

# You can see why the arrows are important. Without 
# them, we would have had to write ${$a[1]}[2] instead 
# of $a[1][2]. For three-dimensional arrays, they let 
# us write $x[2][3][5] instead of the unreadable 
# ${${$x[2]}[3]}[5].
