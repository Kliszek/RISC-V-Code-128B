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
i_name:	.asciz "output.bmp"

mes1:	.asciz "Please type a word:\n"

input:	.space 80
codef:	.asciz "code128b.bin"

.align 8
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
	
	
#TESTING HERE


	la a0, input
	lb a0, (a0)
	jal get_barcode
	lw a0, (a0)		#Testing get_barcode
	
	jal save_file		#Testing save_file


#END OF TESTING

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
	
	la s0, codes
	addi a0, a0, -32
	slli a0, a0, 3
	add a0, s0, a0		#calculate the address of barcode (substract 32, multiply by 8 and add this offset to the codes address)
	
	lw s0, 0(sp)
	addi sp, sp, 4
	jr ra
	
	
save_file:
#description:
#	when a file buffer is ready, this function saves the bmp file
#arguments:
#	none
#return value:
#	none

	addi sp, sp, -4
	sw s0, 0(sp)
	
	li a7, 1024
	li a1, 1
	la a0, i_name
	ecall			#Opens the file for writing
	
	#ADD CONDITION HERE (if a0 == -1 then error)
	
	mv t1, a0
	
	li a7, 64
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall			#Writes the file
	
	mv a0, t1
	li a7, 57
	ecall			#Closes the file
	
	lw s0, 0(sp)
	addi sp, sp, 4
	jr ra
