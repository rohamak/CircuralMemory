# CircuralMemory

CircularMemory
An implementation of a [circular buffer](https://en.wikipedia.org/wiki/Circular_buffer) 
for thread safe testings for the University of Southern California.

Techniques used : FIFO, Mutex, Asynchronous function calls, Multithreads, Atomic class properties. 
Code writing practices :
- The size of buffer could be changed easily by changing a constant value in the code. ( kBufferSize )
- Multilanguage ready.
- All functions and important code segments are documented by comments, to see a function document hold down the 'Option' key whild clicking on the name of the function where function is called.
- Zero code redundency. 
- This could be easily changed to add more multithreading test procedures, such as concurrent reads or writes

Platform : Mac OS X 10.6 or highier is required. You can use the CircularMemory.app as an standalone executable. it's been signed with a Apple certified developer signature, so if you have safeguard turned on it still run.

The main logic of the above implementation is in ViewController.m file.

The useful property of a circular buffer is that it does not need to have its elements shuffled around when one is consumed. 
(If a non-circular buffer were used then it would be necessary to shift all elements when one is consumed.) In other words, 
the circular buffer is well-suited as a FIFO buffer while a standard.
