#name: Ingrid Feng
#studentID: 260803777

.data

#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "test1.txt"
output:	.asciiz "borded.pgm"	#used as output

borderwidth: .word 2   #specifies border width
buffer:  .space 2048		# buffer for upto 2048 bytes
newbuff: .space 2048
headerbuff: .space 2048  #stores header

#any extra data you specify MUST be after this line 
array:	.space 8192		#initialize an array
errOp: 	.asciiz "Error! Open file failed!"
newLine: .asciiz "\n"

	.text
	.globl main

main:	la $a0,input		#readfile takes $a0 as input
	jal readfile


	la $a0,buffer		#$a1 will specify the "2D array" we will be flipping
	la $a1,newbuff		#$a2 will specify the buffer that will hold the flipped array.
	la $a2,borderwidth
	jal bord


	la $a0, output		#writefile will take $a0 as file location
	la $a1,newbuff		#$a1 takes location of what we wish to write.
	jal writefile

	li $v0,10		# exit
	syscall

readfile:
#done in Q1
	li $v0, 13 		# open_file syscall code = 13
	li $a1, 0 		# file flag = read (0)
	syscall
	move $s0, $v0 		# save the file descriptor. $s0 = file
	slt $t0, $s0, $zero 	# if $s0 < 0, errors, $t0 will be set to 1
	bne $t0, $zero, error	# goes to the procedure error
	
	# read the file
	li $v0, 14		# read_file syscall code = 14
	move $a0, $s0		# file descriptor
	la $a1, buffer  	# The buffer that holds the string of the WHOLE file
	move $s1, $a1
	la $a2, 2048		# hardcoded buffer length
	syscall
	
	# close the file
	li $v0, 16         	# close_file syscall code
    	move $a0, $s0      	# file descriptor to close
    	syscall
    	j expro
    	
error: 	li $v0, 4		# print the error message
	la $a0, errOp
	syscall
	
	li $v0, 10		# exit
	syscall 

expro: 	jr $ra			# finish this procedure

bord:
#a0=buffer
#a1=newbuff
#a2=borderwidth
#Can assume 24 by 7 as input
#Try to understand the math before coding!
#EXAMPLE: if borderwidth=2, 24 by 7 becomes 28 by 11.

	# parse numbers into array
	addi $t0, $zero, 0	# set $t0 to 0, index of array
	move $t3, $a0		# index of buffer
	addi $t4, $zero, 0	# set $t4 to 0
	
loop:	lb $t2, ($t3)		# read the next character in buffer
	beq $t2, $zero, startbord
	
	sltiu $t1, $t2, 58	# if $t2 < 58 then set $t1 to 1
	beq $t1, $zero, increB	# not a digit, go to incre
	
	sltiu $t1, $t2, 48	# if $t2 < 48(not a digit 0-9) then set $t1 to 1
	bne $t1, $zero, increB	# not a digit, go to incre
	
	subi $t2, $t2, 48	# get the real digit from ASCII
	beq $t4, 0, onedig	# not the second digit of a number
	add $t2, $t4, $t2	# find the two digit number
	addi $t4, $zero, 0	# set $t4 to 0
	j store			# store it
	
onedig:	addi $t1, $zero, 1	# $t1 = 1
	bne $t2, $t1, store	# this number is only one digit, store
	mul $t4, $t2, 10	# the first digit is one, need to look at the second digit before storing
	j increB
	
store:	sw $t2, array($t0)	# store current number into array	
	addi $t0, $t0, 4	# go to next number in array
increB:	addi $t3, $t3, 1	# next character in buffer
	j loop
	
	# convert each number in array into ASCII and parse into new buffer, adding 15s around
startbord:
	add $t4, $zero, $a1	# index for newbuffer
	lw $s2, ($a2)		# borderwidth
	slt $t0, $zero, $s2	# borderwidth minimum set to 0, if input is negative, also set to 0
				# it does not make sense to have a negative borderwidth
	bne $t0, $zero, nonzero
	li $s2, 0
nonzero:add $t2, $s2, 24	
	add $s3, $t2, $s2	# s3 is width
	move $t2, $s3
	mul $t0, $t2, $s2	# t0 is the total number of rows of 15s above first line of array
	
	addi $t1, $zero, 1
padinit:bne $t1, $zero, init	# this is padding the final zeros (called by padfin)
	beq $t0, $zero, expro	# exit this procedure
init:	beq $t0, $zero, arr	# all 15s are stored

cont:	addi $t3, $zero, 49	# store 15
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t3, $zero, 53
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t3, $zero, 32	# add a space after it
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	subi $t0, $t0, 1	# decrement the counter
	subi $t2, $t2, 1
	
	bne $t2, $zero, loopad	# not the end of this row
	addi $t3, $zero, 10	# store newline character
	sb $t3, ($t4)
	addi $t4, $t4, 1
	move $t2, $s3		# reset t2, s3 is width
	
loopad:	j padinit
	
arr:	addi $t0, $zero, 0	# row index - 1
	addi $t1, $zero, 1	# column index

padbef:	move $t7, $s2		# number of 15s to add after each line
	add $t5, $zero, $zero
	j padaft
loopb:	li $t2, 0
	mul $t2, $t0, 24	# (row index - 1) * num of columns
	add $t2, $t2, $t1	# + column index
	mul $t2, $t2, 4		# * data size per number
	subi $t2, $t2, 4	# decrease 4 bytes to go to the correct address
	
	lw $t3, array($t2)	# load current number
	slti $t5, $t3, 10	# if $t3 < 10, set $t5 to 1
	bne $t5, $zero, ascii	# then change to ASCII directly
	
	addi $t5, $zero, 49	# else, need to set $t5 to 49(ascii of 1, first digit of the two digit num)
	sb $t5, -1($t4)		# store it to the new buffer
	subi $t3, $t3, 10	# minus the two digit number by 10
	
ascii:	addi $t3, $t3, 48	# change to ASCII
	sb $t3, ($t4)		# store it to the new buffer
	addi $t4, $t4, 1
	
	addi $t3, $zero, 32	# add two spaces after it
	sb $t3, ($t4)
	addi $t4, $t4, 1
	sb $t3, ($t4)
	addi $t4, $t4, 1

	bne $t1, 24, next	# if it's not the last entry in this column, go to next number
	
	move $t7, $s2		# number of 15s to add after each line
	addi $t5, $zero, 1
padaft:	beq $t7, $zero, newline
	addi $t3, $zero, 49	# store 15
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t3, $zero, 53
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t3, $zero, 32	# add a space after it
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	subi $t7, $t7, 1
	j padaft
	
newline:beq $t5, $zero, loopb	# all 15s between two lines are padded
	addi $t3, $zero, 10	# store newline character
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	beq $t0, 6, padfin	# it's the last entry in the array, exit loop and pad the final zeros
		
update:	addi $t0, $t0, 1	# update row index
	addi $t1, $zero, 1	# update column index
	j padbef

padfin:	move $t2, $s3
	mul $t0, $t2, $s2	# t0 is the total number of rows of 15s below last line of array
	add $t1, $zero, $zero	# to tell padinit to jr $ra directly after looping
	j padinit

next:	addi $t1, $t1, 1
	j loopb
	

writefile:
#slightly different from Q1.
#use as many arguments as you would like to get this to work.
#make sure the header matches the new dimensions!
	move $s2, $a1		# save the string in the buffer
	lw $t0, borderwidth
	mul $t0, $t0, 2
	addi $t1, $t0, 24
	la $s3, ($t1)		#width
	
	addi $t2, $t0, 7
	la $s4, ($t2)		#height
	
	#open file 
    	li $v0, 13           	# open_file syscall code = 13
    	li $a1, 1           	# file flag = write (1)
    	syscall
    	move $s1, $v0        	# save the file descriptor. $s0 = file
    	
    	slt $t0, $s0, $zero 	# if $s0 < 0, errors, $t0 will be set to 1
	bne $t0, $zero, error	# goes to the procedure error
    	
    	#Write the file
    	li $v0, 15		# write_file syscall code = 15
    	move $a0, $s1		# file descriptor
    	
    	#compute header and store into headerbuff
    	la $t4, headerbuff 	# index for header
	
    	addi $t3, $zero, 80	# store "P"
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t3, $zero, 50	# store "2"
	sb $t3, ($t4)
	addi $t4, $t4, 1
    	
	addi $t3, $zero, 10	# store newline character
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	move $t3, $s3
	li $t7, 0
twodig:	slti $t5, $t3, 10	# if $t3 < 10, set $t5 to 1
	bne $t5, $zero, ascii1	# then change to ASCII directly
	
	addi $t6, $zero, 10
	div $t3, $t6
	mflo $t5
	mfhi $t3
	addi $t5, $t5, 48
	sb $t5, ($t4)		# store it to the new buffer
	addi $t4, $t4, 1
	
ascii1:	addi $t3, $t3, 48	# change to ASCII
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t3, $zero, 32	# a space
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	beq $t7, 1, max
	
	move $t3, $s4		# height
	li $t7, 1
	j twodig
	
max:	addi $t3, $zero, 10	# store newline character
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t3, $zero, 49	# store 15
	sb $t3, ($t4)
	addi $t4, $t4, 1
	addi $t3, $zero, 53	
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t3, $zero, 10	# store newline character
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	li $v0, 15		# write_file syscall code = 15
    	move $a0, $s1		# file descriptor
    	la $a1, headerbuff	# the string of the entries of the matrix
    	la $a2, 100		# length of the string
    	syscall
    	
    	li $v0, 15		# write_file syscall code = 15
    	move $a0, $s1		# file descriptor
    	move $a1, $s2		# the string of the entries of the matrix
    	la $a2, 2048		# length of the string
    	syscall
    	
	#MUST CLOSE FILE IN ORDER TO UPDATE THE FILE
    	li $v0, 16         	# close_file syscall code
    	move $a0, $s1      	# file descriptor to close
    	syscall
    	jr $ra			# finish this procedure
