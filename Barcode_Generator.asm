#-------------------------------------------------------------------------------
#author: Jakub Kliszko
#data : 202x.xx.xx
#description : Generate BMP file with Code 128B barcode of a given word 
#-------------------------------------------------------------------------------
#
#24-bits 50 pixels high BMP files are supported
.eqv MAX_FILE_SIZE 614454	#4096*3*50+54
.eqv MAX_IMAGE_WIDTH 4096
.eqv START_B 104
.eqv STOP 106

	.data
#space for the 4096x50px 24-bits bmp image
.align 4
res:	.space 2
image:	.space MAX_FILE_SIZE
i_name:	.asciz "output.bmp"

mes1:	.asciz "Please specify the width of the narrowest bar (in pixels):\n"
mes2:	.asciz "Please type a text to encode:\n"
mes3:	.asciz "Generating...\n"
input:	.space 80

.align 8
codes:	.space 856
codef:	.asciz "code128b.bin"

c_err:	.asciz "ERROR: There was an error with \"code128b.bin\" file.\n"
s_err:	.asciz "ERROR: There was an error with writing the file.\n"
i_err:	.asciz "ERROR: Provided string has some invalid characters.\n"
l_err:	.asciz "ERROR: Provided string is too long.\n"


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
	ecall			#Prints a message asking to type a width of the narrowest bar
	
	li a7, 5
	ecall			#Reads the number		
	
	mv s0, a0		#Stores the number in s0
	
	
	li a7, 4
	la a0, mes2
	ecall			#Prints a message asking to type a string
	
	li a7, 8
	la a0, input
	li a1, 80
	ecall			#Reads the typed word

	
	
	
	#ANALYZING THE INPUT
	la s1, input
	li s2, 0	
analyze_input:
	lb a0, (s1)

	li t0, '\n'
	beq a0, t0, quit_analyzing_input	#checking if the next character is 0 or new line (LF or CR)
	li t0, '\r'
	beq a0, t0, quit_analyzing_input
	beqz a0, quit_analyzing_input
		
	lb a0, (s1)
	
	la a2, i_err
	li t0, 32
	blt a0, t0, error
	li t0, 127
	bgt a0, t0, error	#error handling (exiting if character is not between 32 and 127, that is when code is not between 0 and 95)

	addi s2, s2, 1
	addi s1, s1, 1
	j analyze_input
quit_analyzing_input:

	li t0, 11
	mul s2, s2, t0
	addi s2, s2, 55		#10+11+length+11+13+10 (quiet zone + start symbol + the string + checksum + stop symbol + quiet zone)
	mul s2, s2, s0		#multiplying by the width of the narrowest bar
				#s2 contains the pixel width of the image
	li t0, MAX_IMAGE_WIDTH
	la a2, l_err
	bgt s2, t0, error	#error handling (if the word is too big for bitmap limit)
	
	li t0, 3
	mul s1, s2, t0		#for now s1 contains number of bytes in row (excluding padding)
	
	
	addi s1, s1, 3
	srli s1, s1, 2
	slli s3, s1, 2		#s3 contains row size with padding
		
	
	li t0, 50
	mul s1, s3, t0		#s1 contains pixel array size
	addi t0, s1, 54

#At this point:	(everything will be used later)
#	s0 - narrowest bar width
#	s1 - pixel array size
#	s2 - pixel width of the image
#	s3 - row size in bytes
	
	li a7, 4
	la a0, mes3
	ecall			#Prints "Generating...:", so the user knows that he doesn't have to type anything anymore	
	
	#GENERATE BMP HEADER
	la a0, image
	li a1, 0x4D42		# "BM"
	sh a1, (a0)
	addi a1, s1, 54		#file size	(pixel array size + (54 = header))
	sw a1, 2(a0)
				#reserved
	sw zero, 6(a0)
	li a1, 54		#pixel array offset
	sb a1, 10(a0)
	
	
	#GENERATE DIB HEADER
	addi a0, a0, 14
	li a1, 40		#DIB Header size
	sw a1, (a0)
				#width
	sw s2, 4(a0)
	li a1, 50		#height
	sw a1, 8(a0)
	li a1, 1		#number of planes
	sh a1, 12(a0)
	li a1, 24		#bits per pixel
	sh a1, 14(a0)
				#compression
	sw zero, 16(a0)
				#size of pixel array
	sw s1, 20(a0)
	li a1, 2835		#DPI (width)
	sw a1, 24(a0)
				#DPI (height)
	sw a1, 28(a0)
				#number of colors in the palette 
	sw zero, 32(a0)
				#important colors (0 = all colors are important)
	sw zero, 36(a0)


	
	#PAINT THE IMAGE WHITE
	la, a0, image	
	addi a0, a0, 54
	li a1, 0xffffffff
	
	mv t0, s1
	add t0, t0, a0
paint_white:
	sw a1, (a0)		#painting 4 bytes at once to speed up the process
	addi a0, a0, 4
	beq a0, t0, quit_painting_white
	j paint_white
quit_painting_white:
	

	#PAINTING
	li a0, START_B		#painting the first starting symbol
	li t0, 10
	mul a1, s0, t0		#calculating where to start: starting after the quiet zone
	mv a2, s0
	mv a3, s3
	jal paint_char
	
	
	la s4, input
	li s5, 1		#index of current character
	li s6, START_B		#THE CHECKSUM INITIAL VALUE	(starting from START B code)
	
read_input_loop:
	lb a0, (s4)
	
	li t0, '\n'
	beq a0, t0, quit_reading_input	#checking if the next character is 0 or new line (LF or CR)
	li t0, '\r'
	beq a0, t0, quit_reading_input
	beqz a0, quit_reading_input
	
	lb a0, (s4)
	addi a0, a0, -32	#a0 contains a code of the next pattern
	
	mul t0, a0, s5
	add s6, s6, t0		#increasing the checksum
	
	mv a2, s0
	mv a3, s3
	
	jal paint_char
	
	addi s4, s4, 1
	addi s5, s5, 1
	j read_input_loop
quit_reading_input:
	
	li t0, 103
	rem s6, s6, t0		#CALCULATED CHECKSUM
	
	mv a0, s6
	mv a2, s0
	mv a3, s3
	jal paint_char		#painting the pattern for the checksum
	
	li a0, STOP
	mv a2, s0
	mv a3, s3
	jal paint_char
	
	addi a0, s1, 54
	jal save_file		#Saving the file


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
#	a1 - image row size in bytes (with padding)
#return value:
#	none
	addi sp, sp, -4
	sw s0, 0(sp)
	
	la a2, image
	addi a2, a2, 54
	
	li s0, 3
	mul a0, a0, s0
	add a0, a2, a0		#a0 contains the address of the first pixel to paint

		
	li s0, 50
	mul s0, s0, a1
	add s0, a0, s0		#s0 is one pixel higher than the highest pixel in the column, the loop goes one pixel lower in each iteration
paint_loop:
	sub s0, s0, a1
	
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
#	a1 - the offset in pixels (from left) to start painting the code
#	a2 - the scaling factor
#	a3 - image row width in bytes (with padding)
#return value:
#	a1 - the offset in pixels (from left) where the next pattern can be drawn

	addi sp, sp, -24
	sw ra, 20(sp)
	sw s0, 16(sp)
	sw s1, 12(sp)
	sw s2, 8(sp)
	sw s3, 4(sp)
	sw s4, 0(sp)
	
	
	
	mv s0, a1				#s0 is the current pixel horizontal location where we paint
	mv s3, a2				#s3 is the scaling factor
	mv s4, a3				#s4 is the image row width
	
	jal get_barcode
	
	mv s1, a0				#s1 is the address to the current bar pattern
	
	
encode_loop:
	lb s2, (s1)
	
	mul s2, s2, s3				#scaling the black bar
	add s2, s2, s0				#s2 is the address at which the paiting (of a current bar) should stop
whole_bar:
	beq s0, s2, quit_painting_whole_bar
	
	mv a0, s0
	mv a1, s4
	jal paint_bar
	
	addi s0, s0, 1
	j whole_bar
quit_painting_whole_bar:
	lb s2, 1(s1)
	
	beqz s2, quit_encode_loop
	
	mul s2, s2, s3				#jump by this amount of pixels (with scaling)
					
	add s0, s0, s2
	addi s1, s1, 2
	j encode_loop
	
quit_encode_loop:	
	
	mv a1, s0
	
	lw s4, 0(sp)
	lw s3, 4(sp)
	lw s2, 8(sp)
	lw s1, 12(sp)
	lw s0, 16(sp)
	lw ra, 20(sp)
	addi sp, sp, 24
	jr ra


	
save_file:
#description:
#	when a file buffer is ready, this function saves the bmp file
#arguments:
#	a0 - image size
#return value:
#	none

	addi sp, sp, -8
	sw s0, 4(sp)
	sw s1, 0(sp)
	
	mv s0, a0		#preserve image size
	
	li a7, 1024
	li a1, 1
	la a0, i_name
	ecall			#Opens the file for writing

	mv s1, a0		#preserve the file decriptor
		

	la a2, s_err
	li a1, -1
	beq a0, a1, error	#error handling
	
	
	li a7, 64
	la a1, image
	mv a2, s0
	ecall			#Writes the file
	
	mv a0, s1		#restore the file decriptor
	li a7, 57
	ecall			#Closes the file
	
	lw s1, 0(sp)
	lw s0, 4(sp)
	addi sp, sp, 8
	jr ra
