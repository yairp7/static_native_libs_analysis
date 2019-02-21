CC = gcc

setup:
	-mkdir ./bin

anti_ptrace_self: setup
	${CC} ./anti_trace/anti_ptrace_self.c -o ./bin/anti_ptrace_self -lpthread 

all: anti_ptrace_self
