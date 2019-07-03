# CombineLab
## Experiments With the Combine Framework

To better understand the workings of Combine, this package implements some of its basic building blocks, including a Publisher, Subscriber, Operator and Subject. There are probably better ways to do these things, but with the current dearth of documentation this code seems to do basically the same things as the builtin components. One probable exception is correctly handling backpressure with infinite publishers.

To experiment with this lab, open Package.swift in Xcode 11 (or later) and run the tests.
