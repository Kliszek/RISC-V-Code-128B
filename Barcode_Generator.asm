#-------------------------------------------------------------------------------
#author: Jakub Kliszko
#data : 202x.xx.xx
#description : Generate BMP file with Code 128B barcode of a given word 
#-------------------------------------------------------------------------------
#
#only 24-bits 600x50 pixels BMP files are supported
.eqv BMP_FILE_SIZE 90054	#row width = 1800	image height = 50	pixel array size = 90000	DIB header = 40		header = 14	file size = 90054
.eqv BYTES_PER_ROW 1800

	.data
#space for the 600x50px 24-bits bmp image
.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE
i_name:	.asciz "output.bmp"

mes1:	.asciz "Please type a word:\n"
input:	.space 80

.align 8
codes:	.space 872
codef:	.asciz "code128b.bin"

c_err:	.asciz "There was an error with \"code128b.bin\" file.\n"
s_err:	.asciz "There was an error with writing the file.\n"


	.text
main:

	
	li a7, 1024
	la a0, codef
	li a1, 0
	ecall			#Opens a file with codes
	
	
	la a2, c_err
	li a1, -1
	beq a0, a1, error	#error handling
	
	
	li a7, 63
	la a1, codes
	li a2, 872
	ecall			#Reads the file
	
	
	
	li a7, 4
	la a0, mes1
	ecall			#Prints a message asking to type a word
	
	li a7, 8
	la a0, input
	li a1, 80
	ecall			#Reads the typed word	
	
	
	
	
	#GENERATE BMP HEADER
	la a0, image
	li a1, 0x4D42		# "BM"
	sh a1, (a0)
	li a1, BMP_FILE_SIZE	#file size
	sw a1, 2(a0)
				#reserved
	sw zero, 6(a0)
	li a1, 54		#pixel array offset
	sb a1, 10(a0)
	
	
	#GENERATE DIB HEADER
	addi a0, a0, 14
	li a1, 40		#DIB Header size
	sw a1, (a0)
	li a1, 600		#width
	sw a1, 4(a0)
	li a1, 50		#height
	sw a1, 8(a0)
	li a1, 1		#number of planes
	sh a1, 12(a0)
	li a1, 24		#bits per pixel
	sh a1, 14(a0)
				#compression
	sw zero, 16(a0)
	li a1, 90000		#size of pixel array
	sw a1, 20(a0)
	li a1, 2835		#DPI (width)
	sw a1, 24(a0)
				#DPI (height)
	sw a1, 28(a0)
				#number of colors in the palette 
	sw zero, 32(a0)
				#important colors (0 = all colors are important)
	sw zero, 36(a0)

	
#TESTING HERE


	la a0, input
	lb a0, (a0)
	jal get_barcode
	lw a0, (a0)		#Testing get_barcode
	
	li a0, 300
	jal paint_bar
	
	jal save_file		#Testing save_file


#END OF TESTING





exit:	
	li a7, 10		#exits the program
	ecall
	
	
	
error:
#description:
#	prints an error message and exits
#arguments:
#	a2 - address to the string
#return value:
#	none
	li a7, 4
	mv a0, a2
	ecall
	j exit
	
	
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
	
	
paint_bar:
#description:
#	paints a bar, WIP
#arguments:
#	a0 - the width at which the white bar will be added
#return value:
#	none
	addi sp, sp, -4
	sw s0, 0(sp)
	
	la a1, image
	addi a1, a1, 54
	
	li s0, 3
	mul a0, a0, s0
	add a0, a1, a0		#the address of the first pixel is in a0 now

		
	li a1, 0xff		#255
	li s0, 90000
	add s0, a0, s0		#s0 is the highest pixel in the column, the loop goes one pixel lower (1800 bytes) in each iteration
paint_loop:
	addi s0, s0, -1800
	
	sb a1, (s0)
	sb a1, 1(s0)
	sb a1, 2(s0)
	
	beq s0, a0, quit_paint_loop
	j paint_loop
quit_paint_loop:
	
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

	mv s0, a0		#preserve the file decriptor
		

	la a2, s_err
	li a1, -1
	beq a0, a1, error	#error handling
	
	
	li a7, 64
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall			#Writes the file
	
	mv a0, s0		#restore the file decriptor
	li a7, 57
	ecall			#Closes the file
	
	lw s0, 0(sp)
	addi sp, sp, 4
	jr ra
