#-------------------------------------------------------------------------------
#author: Jakub Kliszko
#data : 202x.xx.xx
#description : Generate BMP file with Code 128B barcode of a given word 
#-------------------------------------------------------------------------------
#
#only 24-bits 600x50 pixels BMP files are supported
.eqv BMP_FILE_SIZE 90122
.eqv BYTES_PER_ROW 1800

	.data
#space for the 600x50px 24-bits bmp image
.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE

mes1:	.asciz "Please type a word:\n"

input:	.space 80
codef:	.asciz "code128b.bin"
codes:	.space 872

	.text
main:


	li a7, 4
	la a0, mes1
	ecall			#Prints a message asking to type a word
	
	li a7, 8
	la a0, input
	li a1, 80
	ecall			#Reads the typed word
	
	li a7, 1024
	la a0, codef
	li a1, 0
	ecall			#Opens a file with codes
	
	#ADD CONDITION IF FILE ERROR
	
	li a7, 63
	la a1, codes
	li a2, 872
	ecall			#Reads the file
	
	
	la a0, input
	lb a0, (a0)
	jal get_barcodes
	lw a0, (a0)
	

exit:	
	li a7, 10		#exits the program
	ecall
	
get_barcode:
#description:
#	given a char, returns the address to the combination of black/white stripes
#arguments:
#	a0 - the character
#return value:
#	a0 - the address to the combination of stripes
	
	addi sp, sp, -4
	sw s0, 0(sp)		#push s0
	
	#la a0, input
	#lb s0, (a0)		#save 1st letter of input to s0
	
	la s0, codes
	addi a0, a0, -32
	slli a0, a0, 3
	add a0, s0, a0		#calculate the address of barcode
	#lw a0, (a0)
	
	lw s0, 0(sp)
	addi sp, sp, 4
	jr ra
	
	
