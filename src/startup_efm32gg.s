/**************************************************************************//**
 * @file
 * @brief    CMSIS Core Device Startup File for
 *           Energy Micro EFM32GG Device Series
 ******************************************************************************
 *
 * Version: Sourcery G++ 4.4-180
 * Support: https://support.codesourcery.com/GNUToolchain/
 *
 * Copyright (c) 2007, 2008, 2009, 2010 CodeSourcery, Inc.
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions.  No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 *
 *******************************************************************************
 * Energy Micro release version
 * @version 3.20.2
 ******************************************************************************/

/* Vector Table */

    .section ".cs3.interrupt_vector"
    .globl  __cs3_interrupt_vector_em
    .type   __cs3_interrupt_vector_em, %object

__cs3_interrupt_vector_em:
    .long   __cs3_stack                 /* Top of Stack                 */
    .long   __cs3_reset                 /* Reset Handler                */

    .size   __cs3_interrupt_vector_em, . - __cs3_interrupt_vector_em

    .thumb


/* Reset Handler */

    .section .cs3.reset,"x",%progbits
    .thumb_func
    .globl  __cs3_reset_em
    .type   __cs3_reset_em, %function
__cs3_reset_em:
     /* jump to common start code */
    ldr     r0, =SystemInit
    blx     r0
    ldr     r0,=__cs3_start_asm
    bx      r0
    .pool
    .size   __cs3_reset_em,.-__cs3_reset_em
    .thumb

    .end
