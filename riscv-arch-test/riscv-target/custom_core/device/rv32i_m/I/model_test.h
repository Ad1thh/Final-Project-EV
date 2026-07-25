#ifndef _MODEL_TEST_H
#define _MODEL_TEST_H

// 1. Signature Region Boundary Definitions
#define RVMODEL_DATA_BEGIN \
    .align 4; .global begin_signature; begin_signature:

#define RVMODEL_DATA_END \
    .align 4; .global end_signature; end_signature:

// 2. Halt execution via EBREAK (Triggers Testbench Trap)
#define RVMODEL_HALT \
    ebreak;

#define RVMODEL_BOOT

// Mandatory stub macros required by test runner
#define RVMODEL_IO_WRITESTR(_SP, _STR)
#define RVMODEL_IO_CHECK(_R1, _R2, _R3)
#define RVMODEL_SET_MSW_INT
#define RVMODEL_CLEAR_MSW_INT
#define RVMODEL_CLEAR_MTIM_INT
#define RVMODEL_CLEAR_MEXT_INT

#endif