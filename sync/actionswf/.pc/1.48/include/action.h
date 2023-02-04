
#const ActionAdd=0x0A
const ActionSubtract=0x0B
const ActionMultiply=0x0C
const ActionDivide=0x0D

const ActionAnd=0x10
const ActionOr=0x11
const ActionNot=0x12
const ActionPop=0x17
const ActionToInteger=0x18
const ActionGetVariable=0x1C
const ActionSetVariable=0x1D
#const ActionTrace=0x26
const ActionRandomNumber=0x30
const ActionCharToAscii=0x32
const ActionAsciiToChar=0x33
const ActionDelete=0x3A
const ActionDelete2=0x3B
const ActionDefineLocal=0x3C
const ActionCallFunction=0x3D
const ActionReturn=0x3E
const ActionModulo=0x3F
const ActionNewObject=0x40
const ActionDefineLocal2=0x41
const ActionTypeOf=0x44
const ActionEnumerate=0x46
const ActionAdd2=0x47
const ActionLess2=0x48
const ActionEquals2=0x49
const ActionPushDuplicate=0x4C
const ActionGetMember=0x4E
const ActionSetMember=0x4F
const ActionIncrement=0x50
const ActionDecrement=0x51
const ActionCallMethod=0x52
const ActionNewMethod=0x53
const ActionBitAnd=0x60
const ActionBitOr=0x61
const ActionBitXor=0x62
const ActionBitLShift=0x63
const ActionBitRShift=0x64
const ActionBitURShift=0x65
const ActionGreater=0x67
const ActionStoreRegister=0x87
const ActionConstantPool=0x88
const ActionPush=0x96
    const ap_Null=2
    const ap_Undefined=3
    const ap_RegisterNumber=4
    const ap_Boolean=5
    const ap_double=6
    const ap_Integer=7
    const ap_Constant8=8
    const ap_Constant16=9
const ActionJump=0x99
const ActionDefineFunction=0x9B
const ActionIf=0x9D
#const ActionGotoFrame2=0x9F

const call_action_left=0xf1011010
const call_action_right=0xf2022020
const function_action=0xf3033030
const new_action=0xf4044040
const square_bracket_start=0xf5055050
const mixt_equal=0xf6066060
const compare_action=0xf7077070
const parenthesis_start=0xf8088080
const break_flag=0xf9099090
const continue_flag=0xfa0AA0a0
#
const for_marker=0xfb0BB0b0
const for_three=0xfc0CC0c0
const inter_for=0xfd0DD0d0
#
const ifElse_start=0xfe0EE0e0

const brace_blocks_function=0x7fFFffFF

const to_flags=0x100*0x100*0x100
const consecutive_flag=0x80*to_flags
const else_flag=0x40*to_flags
#const all_flags=consecutive_flag|else_flag
const normal_marker=0x01010202
const if_marker=0x03030404
const while_marker=0x05050606
const function_marker=0x07070808

const block_end=0xfbBBbbBB
const block_else_end=0xfcCCccCC
const whileblock_end=0xfdDDddDD
const args_end=0xfeEEeeEE
const math_end=0xffFFffFF

#

const get_member=0
