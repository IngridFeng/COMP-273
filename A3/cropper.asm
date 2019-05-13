#name: Ingrid Feng
#studentID: 260803777

.data

#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "test1.txt"
output:	.asciiz "cropped.pgm"	#used as output
buffer:  .space 2048		# buffer for upto 2048 bytes
newbuff: .space 2048

#here I assume that x1, x2 are column numbers, and y1,y2 are row numbers (there are 24 columns and 7 rows)
x1: .word 1
x2: .word 2
y1: .word 3
y2: .word 4
headerbuff: .space 2048  #stores header
#any extra .data you specify MUST be after this line 
array:	.space 2048		#initialize an array
errOp: 	.asciiz "Error! Open file failed!"

	.text
	.globl main

main:	la $a0, input		#readfile takes $a0 as input
	jal readfile

    #load the appropriate values into the appropriate registers/stack positions
    #appropriate stack positions outlined in function*
        subi $sp, $sp, 24	# space on stack
    	la $a0, x1
    	la $a1, x2
    	la $a2, y1
    	la $a3, y2
    	la $t6, buffer
    	la $t7, newbuff
    	
	sw $t7, 20($sp)
	sw $t6, 16($sp)
	sw $a3, 12($sp)
	sw $a2, 8($sp)
	sw $a1, 4($sp)
	sw $a0, 0($sp)
	jal crop
	
	lw $t1, 20($sp)
	lw $t0, 16($sp)
	addi $sp, $sp, 24	# space on stack
	    	
	la $a0, output		#writefile will take $a0 as file location
	la $a1, newbuff		#$a1 takes location of what we wish to write.
	#add what ever else you may need to make this work.
	la $a2, headerbuff
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

crop:
#a0=x1
#a1=x2
#a2=y1
#a3=y2
#16($sp)=buffer
#20($sp)=newbuffer that will be made
#Remember to store ALL variables to the stack as you normally would,
#before starting the routine.
#Try to understand the math before coding!
#There are more than 4 arguments, so use the stack accordingly.
	lw $t7, 20($sp)		# new buffer
	lw $t6, 16($sp)		# buffer
	lw $a3, 12($sp)		# a3=y2
	lw $a2, 8($sp)		# a2=y1
	lw $a1, 4($sp)		# a1=x2
	lw $a0, 0($sp)		# a0=x1
	# I use 1-24 and 1-7 for column and row indices in other questions for computation convenience
	# I read from discussion board that we are supposed to use 0-23 and 0-6 for x1,x2,y1,y2
	# therefore I would add 1 to each of x1,x2,y1,y2 
	
	# parse numbers into array
	addi $t0, $zero, 0	# set $t0 to 0, index of array
	move $t3, $t6		# index of buffer
	addi $t4, $zero, 0	# set $t4 to 0
	
loop:	lb $t2, ($t3)		# read the next character in buffer
	beq $t2, $zero, startcrop
	
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
	
	# start cropping
startcrop:
	lw $t0, ($a2)		# row index - 1 (num of rows before this number)
	lw $t1, ($a0)
	addi $t1, $t1, 1	# column index
	add $t4, $zero, $t7	# index for newbuffer

loopc:	mul $t2, $t0, 24	# (row index - 1) * num of columns
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

	lw $t3, ($a1)
	addi $t3, $t3, 1	# $t3 = $a1+1
	bne $t1, $t3, next	# if it's not the last entry in this row, go to next number 
	lw $t3, ($a3)
	beq $t0, $t3, exproc	# it's the last entry in the entire cropped section, exit loop
	
	addi $t3, $zero, 10	# store newline character
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t0, $t0, 1	# update row index
	lw $t1, ($a0)
	addi $t1, $t1, 1	# column index
	j loopc
	
next:	addi $t1, $t1, 1
	j loopc

exproc: sw $t7, 20($sp)		# new buffer
	sw $t6, 16($sp)		# buffer
	sw $a3, 12($sp)		# a3=y2
	sw $a2, 8($sp)		# a2=y1
	sw $a1, 4($sp)		# a1=x2
	sw $a0, 0($sp)		# a0=x1
	jr $ra
	
writefile:
#slightly different from Q1.
#use as many arguments as you would like to get this to work.
#make sure the header matches the new dimensions!
	move $s2, $a1		# save the string in the buffer
	
	lw $t0, x1
	lw $t1, x2
	sub $t0, $t1, $t0
	addi $t0, $t0, 1
	la $s3, ($t0)		#width
	
	lw $t2, y1
	lw $t3, y2
	sub $t2, $t3, $t2
	addi $t2, $t2, 1
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
    	move $t4, $a2 		# index for headerbuff
	
    	addi $t3, $zero, 80	# store "P"
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	addi $t3, $zero, 50	# store "2"
	sb $t3, ($t4)
	addi $t4, $t4, 1
    	
	addi $t3, $zero, 10	# store newline character
	sb $t3, ($t4)
	addi $t4, $t4, 1
	
	move $t3, $s3		# width
	slti $t5, $t3, 10	# if $t3 < 10, set $t5 to 1
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
	
	move $t3, $s4		# height
	addi $t3, $t3, 48	# change to ASCII
	sb $t3, ($t4)		# store it to the new buffer
	addi $t4, $t4, 1
	
	addi $t3, $zero, 10	# store newline character
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
    	move $a1, $a2		# the string of the entries of the matrix
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