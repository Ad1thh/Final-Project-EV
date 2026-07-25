#ifndef _MODEL_TEST_H
#define _MODEL_TEST_H

// 1. Target Macros for Register & Memory Setup
#define RVMODEL_DATA_BEGIN \
    .align 4; .global begin_signature; begin_signature:

#define RVMODEL_DATA_END \
    .align 4; .global end_signature; end_signature:

// 2. Halt Execution via ebreak
#define RVMODEL_HALT \
    ebreak;

#define RVMODEL_BOOT

#endif