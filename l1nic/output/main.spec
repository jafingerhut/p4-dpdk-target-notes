

struct metadata_t {
	bit<32> pna_main_input_metadata_input_port
	bit<32> pna_main_output_metadata_output_port
}
metadata instanceof metadata_t

regarray direction size 0x100 initval 0
apply {
	rx m.pna_main_input_metadata_input_port
	jmpneq LABEL_FALSE m.pna_main_input_metadata_input_port 0x0
	mov m.pna_main_output_metadata_output_port 0x1
	jmp LABEL_END
	LABEL_FALSE :	mov m.pna_main_output_metadata_output_port 0x0
	LABEL_END :	tx m.pna_main_output_metadata_output_port
}


