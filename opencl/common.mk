OPENCL_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
include $(OPENCL_DIR)/../common.mk

CPPFLAGS += -I$(OPENCL_DIR)/_CL_headers
LDLIBS   += -lOpenCL
