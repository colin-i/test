
include "ascii.h"

const TRUE=1
const FALSE=0

const NULL=0

#const MAX_PATH=260

#const ENOENT=2

const BYTE=1
const WORD=2
const DWORD=4
const QWORD=8

const void=0

const SEEK_SET=0
const SEEK_CUR=1
const SEEK_END=2

const block_size=0x1000

const mem_struct__size_off=4
const mem_struct_size=8

const mem_exp_init=0
const mem_exp_add=1
const mem_exp_done=2
const mem_exp_part_done=3
const mem_exp_change=4
const mem_exp_change_back=5
const mem_exp_get_block=6
const mem_exp_free=7

const NBits_size=5

const ids_set=0
const ids_free=1
const ids_get=2
const ids_get_pointer=3
const ids_all_free=4
const ids_counter=5

const negative_means_action_sprite_pool=0x80*0x100*0x100*0x100
const fd_error=-1
const fd_none=fd_error
const not_an_id=-1
const dword_to_string_chars=1+9+1

const End=0
const ShowFrame=1
const SetBackGroundColor=9
const DoAction=12
const PlaceObject2=26
const RemoveObject2=28
const DefineShape3=32
            const no_fill=-1
        const solid_fill=0
        const repeating_bitmap_fill=0x40
const DefineBitsLossless=20
const DefineButton2=34
const DefineBitsLossless2=36
const DefineEditText=37
const DefineSprite=39
const DefineFont2=48
const ExportAssets=56

include "action.h"

const ButtonStateUp=1
const ButtonStateOver=2*ButtonStateUp
const ButtonStateDown=2*ButtonStateOver
const ButtonStateHitTest=2*ButtonStateDown

include "text.h"

const StateMoveTo=1
const StateFillStyle0=2*StateMoveTo
const StateFillStyle1=2*StateFillStyle0
const StateLineStyle=2*StateFillStyle1
#const StateNewStyles=2*StateLineStyle

const FontFlagsHasLayout=0x80
#const FontFlagsShiftJIS=0x40
#const FontFlagsSmallText=0x20
#const FontFlagsANSI=0x10
#const FontFlagsWideOffsets=8
#const FontFlagsWideCodes=4
#const FontFlagsItalic=2
#const FontFlagsBold=1

include "lin.h" "win.h"

Const _O_RDONLY=0;Const _O_WRONLY=0x0001;Const _O_TRUNC=0x0200
Const _open_read=_O_RDONLY|flag_O_BINARY
Const _open_write_base=_O_WRONLY|flag_O_BINARY|flag_O_CREAT
Const _open_write=_open_write_base|_O_TRUNC
