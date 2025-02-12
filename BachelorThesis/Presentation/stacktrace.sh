#0  0x00007ffff786d6e3 in sat::local_search::flip_walksat(unsigned int) () from ./prefix/bin/libz3.so
(gdb) bt
#0  0x00007ffff786d6e3 in sat::local_search::flip_walksat(unsigned int) () from ./prefix/bin/libz3.so
#1  0x00007ffff786dce8 in sat::local_search::propagate(sat::literal) () from ./prefix/bin/libz3.so
#2  0x00007ffff786e918 in sat::local_search::pick_flip_walksat() () from ./prefix/bin/libz3.so
#3  0x00007ffff786ed02 in sat::local_search::walksat() () from ./prefix/bin/libz3.so
#4  0x00007ffff7870b08 in sat::local_search::check(unsigned int, sat::literal const*, sat::parallel*) ()
   from ./prefix/bin/libz3.so
#5  0x00007ffff782b651 in sat::solver::invoke_local_search(unsigned int, sat::literal const*) ()