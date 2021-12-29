#-------------------------------------------------------------------------------
#author: Jakub Kliszko
#data : 202x.xx.xx
#description : Generate BMP file with Code 128B barcode of a given word 
#-------------------------------------------------------------------------------
#
#only 24-bits 600x50 pixels BMP files are supported
.eqv BMP_FILE_SIZE 90054	#row width = 1800	image height = 50	pixel array size = 90000	DIB header = 40		header = 14	file size = 90054
.eqv BYTES_PER_ROW 1800
.eqv START_B 104

	.data
#space for the 600x50px 24-bits bmp image
.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE
i_name:	.asciz "output.bmp"

mes1:	.asciz "Please type a text to encode:\n"
mes2:	.asciz "Please specify the width of the narrowest bar (in pixels):\n"
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
	ecall			#Prints a message asking to type a string
	
	li a7, 8
	la a0, input
	li a1, 80
	ecall			#Reads the typed word	
	
	
	li a7, 4
	la a0, mes2
	ecall			#Prints a message asking to type a width of the narrowest bar
	
	li a7, 5
	ecall			#Reads the number		
	
	mv s0, a0		#Stores the number in s0
	
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

	
	#PAINT THE IMAGE WHITE	
	addi a0, a0, 40
	li a1, 0xffffffff
	
	li t0, 90000
	add t0, t0, a0
paint_white:
	sw a1, (a0)		#painting 4 bytes at once to speed up the process
	addi a0, a0, 4
	beq a0, t0, quit_painting_white
	j paint_white
quit_painting_white:
	
	
#TESTING HERE


	#la a0, input
	#lb a0, (a0)
	#jal get_barcode
	#lw a0, (a0)		#Testing get_barcode
	
	li a0, START_B
	li a1, 300
	mv a2, s0
	jal paint_char
	li a0, 'W'
	addi a0, a0, -32
	mv a2, s0
	jal paint_char
	li a0, 'i'
	addi a0, a0, -32
	mv a2, s0
	jal paint_char
	
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
#	given a code, returns the address to the combination of black/white stripes
#arguments:
#	a0 - the code
#return value:
#	a0 - the address to the combination of stripes
	
	addi sp, sp, -4
	sw s0, 0(sp)		#push s0
	
	la s0, codes
	slli a0, a0, 3
	add a0, s0, a0		#calculate the address of barcode (multiply by 8 and add this offset to the codes address)
	
	lw s0, 0(sp)
	addi sp, sp, 4
	jr ra
	
	
paint_bar:
#description:
#	paints a black bar at a given width on the bitmap
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

		
	li s0, 90000
	add s0, a0, s0		#s0 is the highest pixel in the column, the loop goes one pixel lower (1800 bytes) in each iteration
paint_loop:
	addi s0, s0, -1800
	
	sb zero, (s0)
	sb zero, 1(s0)
	sb zero, 2(s0)
	
	beq s0, a0, quit_paint_loop
	j paint_loop
quit_paint_loop:
	
	lw s0, 0(sp)
	addi sp, sp, 4
	jr ra
	
	
paint_char:
#description:
#	paints a bar pattern of a character on the bitmap at given location
#arguments:
#	a0 - the character code
#	a1 - the width in pixels (from left) to start painting the code
#	a2 - the scaling factor
#return value:
#	a1 - the width in pixels (from left) where the next pattern can be drawn

	addi sp, sp, -20
	sw ra, 16(sp)
	sw s0, 12(sp)
	sw s1, 8(sp)
	sw s2, 4(sp)
	sw s3, 0(sp)
	
	
	
	mv s0, a1				#s0 is the current pixel horizontal location where we paint
	mv s3, a2				#s3 is the scaling factor
	
	jal get_barcode
	
	mv s1, a0				#s1 is the address to the current bar pattern
	
	
encode_loop:
	lb s2, (s1)
	beqz s2, quit_encode_loop
	
	mul s2, s2, s3				#scaling the black bar
	add s2, s2, s0				#s2 is the address at which the paiting (of a current bar) should stop
white_bar:
	beq s0, s2, quit_painting_white_bar
	
	mv a0, s0
	jal paint_bar
	
	addi s0, s0, 1
	j white_bar
quit_painting_white_bar:
	lb s2, 1(s1)
	mul s2, s2, s3				#jump by this amount of pixels (with scaling)
					
	add s0, s0, s2
	addi s1, s1, 2
	j encode_loop
	
quit_encode_loop:	
	
	mv a1, s0
	
	lw s2, 0(sp)
	lw s2, 4(sp)
	lw s1, 8(sp)
	lw s0, 12(sp)
	lw ra, 16(sp)
	addi sp, sp, 20
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
