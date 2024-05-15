#!/bin/bash
sed -e '0,/^execve(/d;/^orc_trace(/d;/^+++ /d;s/\(mmap([^,]*\),[^,]*/\1/;s/mmap(0x\([0-9a-f]*\),\(.*\)= 0x\1/mmap(0X,\2= 0X/;s/\(mmap(NULL,.*\)= 0x[0-9a-f]*/\1= 0X/;s///;s/^\(madvise\|mprotect\)(0x[0-9a-z]*, [0-9]*, /\1(/;s/^munmap(0x[0-9a-f]*, [0-9]*) */munmap() /' | sort | uniq -c | sort -nr
