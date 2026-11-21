.RAMSECTION "RAM"
z_L: ds 3 ;0-2
CursorX: ds 1 ;3
CursorY: ds 1 ;4
func_ram: ds 4 ;5-8
nmi_count: ds 2 ;9-$a
bg1_scrx: ds 2; $b-$c
bg1_scry: ds 2; $d-$e
bg2_scrx: ds 2; $f-$10
bg2_scry: ds 2; $11-$12
random_num: ds 2; $13-$14
object_count: ds 1 ; $15
pad: ds $ea ;$16
STACK: ds $100 ;$100
SHADOW_OAM: ds $200 ;$200
SHADOW_OAM2: ds $20 ;$400
OBJECTS: ds $100 ; $420
.ENDS