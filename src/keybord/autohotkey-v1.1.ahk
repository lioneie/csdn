; xps13 9305

Enter::Insert
`::Esc
CapsLock::LControl
'::RControl
LControl::LWin
RAlt::LAlt ; MobaXterm不能使用RAlt

LWin::return
RControl::return

#If, GetKeyState("LWin", "P") or GetKeyState("RControl", "P")
Backspace::Delete
j::Enter
n::Down
p::Up
b::Left
f::Right
c::CapsLock
a::Home
e::End
v::PgDn
m::PgUp
s::PrintScreen
`::`
Enter::"
$SC027::' ; 封号
1::F1
2::F2
3::F3
4::F4
5::F5
6::F6
7::F7
8::F8
9::F9
0::F10
-::F11
=::F12
; Space::LWin ; 不起作用
