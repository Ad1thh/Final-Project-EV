OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .text : { *(.text.init) *(.text) }
  . = ALIGN(0x100);
  .data : { *(.data) }
  . = ALIGN(0x100);
  .bss : { *(.bss) }
  _end = .;
}